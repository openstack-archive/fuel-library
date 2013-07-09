class mysql::replicator (
  $node_address    =  $::ipaddress,
  $node_addresses     =  [$node_address],
  $service_name    =  $mysql::params::service_name,
  $rep_user        =  'replicator',
  $rep_pass        =  'replicant666',
  $replication_roles = "SELECT, PROCESS, FILE, SUPER, REPLICATION CLIENT, REPLICATION SLAVE, RELOAD",

  ) {

  #corosync service order
  Cs_commit['mysql']    -> Service['mysqld']
  Cs_property <||>      -> Cs_shadow <||>
  Cs_shadow['mysql']    -> Service['mysqld']
  Cs_commit <| title == 'internal-vip' |> -> Cs_shadow['mysql']

  $allowed_hosts = '%'
  #$allowed_hosts = 'localhost'



  Class['mysql::config'] -> Cs_resource['p_mysql']

 
  Class['openstack::corosync'] -> Cs_resource['p_mysql']

  file { "/tmp/repl_create.sql" :
    ensure  => present,
    content => template("mysql/repl_create.sql.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,

  ### Start hacks
  } ->
  file { '/usr/lib/ocf/resource.d/heartbeat/mysql': 
    ensure => present,
    source => 'puppet:///modules/mysql/ocf-mysql',
    owner => 'root',
    group => 'root',
    mode => 0755,
  } ->
  file { '/root/.ssh/id_rsa_mysql':
    ensure => present,
    source => 'puppet:///modules/mysql/id_rsa_mysql',
    owner => 'root',
    group => 'root',
    mode => 0600,
  } ->
  file { '/root/.ssh/id_rsa_mysql.pub':  
    ensure => present,
    source => 'puppet:///modules/mysql/id_rsa_mysql.pub',
    owner => 'root',
    group => 'root',
    mode => 0644,
  } ->
  exec { 'add_mysql_ssh_pubkey':
    command => 'cat /root/.ssh/id_rsa_mysql.pub > /root/.ssh/authorized_keys2 && chmod 600 /root/.ssh/authorized_keys2',
    path => '/bin:/usr/bin:/sbin:/usr/sbin',
    unless => 'test -f /root/authorized_keys2 && grep -q "$(cat /root/.ssh/id_rsa.mysql.pub)" /root/authorized_keys2',
  }
  #Sync from second host (first slave) to second slave
  #Refer to: http://dev.mysql.com/doc/refman/5.1/en/replication-howto-additionalslaves.html
  #TODO refactor to support >3 nodes
  if ( $::hostname == $node_addresses[2] ) or ( $node_address == $node_addresses[2] ) {
    $existing_slave = $node_addresses[1]
    exec { 'stop_mysql_slave_on_second_controller':
       command => "ssh -i /root/.ssh/id_rsa_mysql -o StrictHostKeyChecking=no root@${existing_slave} 'mysql -NBe \"stop slave;\"'",
       require => Exec['add_mysql_ssh_pubkey'],
       unless  => "mysql -NBe 'show slave status;' | grep -q ${rep_user}",
       before  => Exec['copy_mysql_data_dir'],
    }
    exec { 'copy_mysql_data_dir': 
       command => "rsync -e 'ssh -i /root/.ssh/id_rsa_mysql -o StrictHostKeyChecking=no' -vaz root@${existing_slave}:/var/lib/mysql/. /var/lib/mysql/.",
       require => Exec['add_mysql_ssh_pubkey'],
       unless  => "mysql -NBe 'show slave status;' | grep -q ${rep_user}",
    } ->
    exec { 'start_mysql_slave_on_second_controller':
       command => "ssh -i /root/.ssh/id_rsa_mysql -o StrictHostKeyChecking=no root@${existing_slave} 'mysql -NBe \"start slave;\"'",
       require => Exec['add_mysql_ssh_pubkey'],
       unless  => "mysql -NBe 'show slave status;' | grep -q ${rep_user}",
    }
  }
 
  cs_shadow { 'mysql': cib => 'mysql' } ->
  cs_resource { "p_mysql":
    ensure          => present,
    primitive_class => 'ocf',
    provided_by     => 'heartbeat',
    primitive_type  => 'mysql',
    cib             => 'mysql',
    multistate_hash => {'type'=>'master'},
    ms_metadata     => {'notify'             => "true"},
    parameters      => {
      'binary' => "/usr/bin/mysqld_safe",
      'test_table'         => 'mysql.user',
      'replication_user'   => $rep_user,
      'replication_passwd' => $rep_pass,
      'additional_parameters' => '"--init-file=/tmp/repl_create.sql"',
    },
    operations   => {
      'monitor'  => { 'interval' => '20', 'timeout'  => '30' },
      'start'    => { 'timeout' => '360' },
      'stop'     => { 'timeout' => '360' },
      'promote'  => { 'timeout' => '360' },
      'demote'   => { 'timeout' => '360' },
      'notify'   => { 'timeout' => '360' },
    }
  }->


  cs_commit { 'mysql': cib => 'mysql' } ->

  service { 'mysqld':
    name     => "p_${service_name}",
    ensure   => 'running',
    enable   => true,
    require  => [Package['mysql-server'], Cs_commit['mysql']],
    provider => 'pacemaker',
  }

  #Tie internal-vip to p_mysql
  cs_colocation { 'mysql_to_internal-vip': 
    primitives => ['internal-vip','master_p_mysql:Master'],
    score      => 'INFINITY',
    require    => [Cs_resource['p_mysql'], Cs_commit['mysql']],
  } 

# Not used because we need to start mysql for the first time 
# with corosync with init script to create users
#  database_user { "${user}@${name}":
#    password_hash => mysql_password($password),
#    provider => 'mysql',
#  }
#  database_grant { "${user}@${name}":
#    privileges => ['Super_priv'],
#    provider => 'mysql',
#    require => Database_user["${user}@${name}"]
#  }
}
