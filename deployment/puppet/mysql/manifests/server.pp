# Class: mysql::server
#
# manages the installation of the mysql server.  manages the package, service,
# my.cnf
#
# Parameters:
#   [*package_name*] - name of package
#   [*service_name*] - name of service
#   [*config_hash*]  - hash of config parameters that need to be set.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mysql::server (
  $custom_setup_class      = undef,
  $package_name            = $mysql::params::server_package_name,
  $package_ensure          = 'present',
  $service_name            = $mysql::params::service_name,
  $service_provider        = $mysql::params::service_provider,
  $config_hash             = {},
  $enabled                 = true,
  $galera_cluster_name     = undef,
  $primary_controller      = false,
  $galera_node_address     = undef,
  $galera_nodes            = undef,
  $mysql_skip_name_resolve = false,
  $server_id               = $mysql::params::server_id,
  $rep_user                = 'replicator',
  $rep_pass                = 'replicant666',
  $replication_roles       = "SELECT, PROCESS, FILE, SUPER, REPLICATION CLIENT, REPLICATION SLAVE, RELOAD",
  $use_syslog              = false,
  $initscript_file         = 'puppet:///modules/mysql/mysql-single.init',
  $root_password           = 'UNSET',
  $old_root_password       = '',
  $etc_root_password       = true,
  $bind_address            = '0.0.0.0',
  $use_syslog              = true,
) inherits mysql::params {

  if ($config_hash['config_file']) {
    $config_file_real = $config_hash['config_file']
  } else {
    $config_file_real = $mysql::params::config_file
  }

  class { 'mysql::password' :
    root_password     => $root_password,
    old_root_password => $old_root_password,
    etc_root_password => $etc_root_password,
    config_file       => $config_file_real,
  }

  class { 'mysql::config' :
    bind_address       => $bind_address,
    use_syslog         => $use_syslog,
    custom_setup_class => $custom_setup_class,
    config_file        => $config_file_real,
  }

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}
  if ($custom_setup_class == undef) {
    include mysql
    Class['mysql::server'] -> Class['mysql::config']
    Class['mysql']         -> Class['mysql::server']

    if !defined(Package[mysql-client]) {
      package { 'mysql-client':
        name   => $package_name,
      }
    }
    package { 'mysql-server':
      name   => $package_name,
    }
    if $::operatingsystem == 'RedHat' {
      file { "/etc/init.d/mysqld":
        ensure  => present,
        source  => $initscript_file,
        mode    => '0755',
        owner   => 'root',
      }
      File['/etc/init.d/mysqld'] -> Service['mysql']
    }
    Package[mysql-client] -> Package[mysql-server]

    service { 'mysql':
      name     => $service_name,
      ensure   => $enabled ? { true => 'running', default => 'stopped' },
      enable   => $enabled,
      require  => Package['mysql-server'],
      provider => $service_provider,
    }
  }
  elsif ($custom_setup_class == 'pacemaker_mysql')  {
    include mysql
    Package[mysql-server] -> Class['mysql::config']
    Package[mysql-server] -> Cs_shadow['mysql']
    Package[mysql-client] -> Package[mysql-server]
    Cs_commit['mysql']    -> Service['mysql']
    #Cs_property <||> -> Cs_shadow <||>
    #Cs_shadow['mysql']    -> Service['mysql']

    $config_hash['custom_setup_class'] = $custom_setup_class
    $allowed_hosts = '%'

    create_resources( 'class', { 'mysql::config' => $config_hash })
    Class['mysql::config'] -> Cs_resource["p_${service_name}"]

    if !defined(Package[mysql-client]) {
      package { 'mysql-client':
        name   => $package_name,
      }
    }

    package { 'mysql-server':
      name   => $package_name,
    } ->
    exec { "create-mysql-table-if-missing":
      command => "/usr/bin/mysql_install_db --datadir=$mysql::params::datadir --user=mysql && chown -R mysql:mysql $mysql::params::datadir",
      path => '/bin:/usr/bin:/sbin:/usr/sbin',
      unless => "test -d $mysql::params::datadir/mysql",
    }

    Class['openstack::corosync'] -> Cs_resource["p_${service_name}"]

    file { '/tmp/repl_create.sql' :
      ensure  => present,
      content => template('mysql/repl_create.sql.erb'),
      owner => 'root',
      group => 'root',
      mode  => '0644',
    }

    ### Start hacks
    file { '/usr/lib/ocf/resource.d/heartbeat/mysql':
      ensure  => present,
      source  => 'puppet:///modules/mysql/ocf-mysql',
      owner   => 'root',
      group   => 'root',
      mode    => 0755,
      require => File['/tmp/repl_create.sql'],
    } ->
    install_ssh_keys {'root_ssh_key_for_mysql':
      ensure           => present,
      user             => 'root',
      private_key_path => '/var/lib/astute/mysql/mysql',
      public_key_path  => '/var/lib/astute/mysql/mysql.pub',
      private_key_name => 'id_rsa_mysql',
      public_key_name  => 'id_rsa_mysql.pub',
      authorized_keys  => 'authorized_keys',
    }
    if ( $::hostname == $galera_nodes[2] ) or ( $galera_node_address == $galera_nodes[2] ) {
      $existing_slave = $galera_nodes[1]
      exec { 'stop_mysql_slave_on_second_controller':
         command => "ssh -i /root/.ssh/id_rsa_mysql -o StrictHostKeyChecking=no root@${existing_slave} 'mysql -NBe \"stop slave;\"'",
         require => Install_ssh_keys['root_ssh_key_for_mysql'],
         unless  => "mysql -NBe 'show slave status;' | grep -q ${rep_user}",
      } ->
      exec { 'copy_mysql_data_dir':
         command => "rsync -e 'ssh -i /root/.ssh/id_rsa_mysql -o StrictHostKeyChecking=no' -vaz root@${existing_slave}:/var/lib/mysql/. /var/lib/mysql/.",
         unless  => "mysql -NBe 'show slave status;' | grep -q ${rep_user}",
      } ->
      exec { 'start_mysql_slave_on_second_controller':
         command => "ssh -i /root/.ssh/id_rsa_mysql -o StrictHostKeyChecking=no root@${existing_slave} 'mysql -NBe \"start slave;\"'",
         unless  => "mysql -NBe 'show slave status;' | grep -q ${rep_user}",

      }
    }
    ### end hacks

    cs_shadow { 'mysql': cib => 'mysql' } ->
    cs_resource { "p_${service_name}":
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

    service { 'mysql':
      name     => "p_${service_name}",
      ensure   => 'running',
      enable   => true,
      require  => [Package['mysql-server'], Cs_commit['mysql']],
      provider => 'pacemaker',
    }

    #Tie vip__management_old to p_mysqld
    cs_colocation { 'mysql_to_internal-vip':
      primitives => ['vip__management_old',"master_p_${service_name}:Master"],
      score      => 'INFINITY',
      require    => [Cs_resource["p_${service_name}"], Cs_commit['mysql']],
    }

  }
  elsif ($custom_setup_class == 'galera')  {
    Class['galera'] -> Class['mysql::server']
    class { 'galera':
      cluster_name       => $galera_cluster_name,
      primary_controller => $primary_controller,
      node_address       => $galera_node_address,
      node_addresses     => $galera_nodes,
      skip_name_resolve  => $mysql_skip_name_resolve,
      use_syslog         => $use_syslog,
    }

  }

   else {
    require($custom_setup_class)
  }
}

