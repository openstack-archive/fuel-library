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
  $custom_setup_class = undef,
  $package_name     = $mysql::params::server_package_name,
  $package_ensure   = 'present',
  $service_name     = $mysql::params::service_name,
  $service_provider = $mysql::params::service_provider,
  $config_hash      = {},
  $enabled          = true,
  $galera_cluster_name = undef,
  $primary_controller = primary_controller,
  $galera_node_address = undef,
  $galera_nodes = undef,
  $mysql_skip_name_resolve = false,
  $use_syslog              = false,
) inherits mysql::params {
    
  if ($custom_setup_class == undef) {
    include mysql
    Class['mysql::server'] -> Class['mysql::config']
    Class['mysql']         -> Class['mysql::server']

    create_resources( 'class', { 'mysql::config' => $config_hash } )
#    exec { "debug-mysql-server-installation" :
#      command     => "/usr/bin/yum -d 10 -e 10 -y install MySQL-server-5.5.28-6 2>&1 | tee mysql_install.log",
#      before => Package["mysql-server"],
#      logoutput => true,
#    }
    if !defined(Package[mysql-client]) {
      package { 'mysql-client':
        name   => $package_name,
       #ensure => $mysql::params::client_version,
      }
    }
    package { 'mysql-server':
      name   => $package_name,
     #ensure => $mysql::params::server_version,
     #require=> Package['mysql-shared'],
    }
    Package[mysql-client] -> Package[mysql-server]
 
    service { 'mysqld':
      name     => $service_name,
      ensure   => $enabled ? { true => 'running', default => 'stopped' },
      enable   => $enabled,
      require  => Package['mysql-server'],
      provider => $service_provider,
    }
  }
  elsif ($custom_setup_class == 'pacemaker_mysql')  {
    include mysql
    #Class['mysql::server'] -> Class['mysql::config']
    Package[mysql-server] -> Class['mysql::config']
    Package[mysql-client] -> Package[mysql-server]
    Cs_commit['mysql']    -> Service['mysqld']
    #Cs_resource['p_mysql'] -> Cs_shadow['mysql']
    Cs_property <||> -> Cs_shadow <||>
    Cs_shadow['mysql']    -> Service['mysqld']
    #Cs_commit['vip'] -> Cs_shadow['mysql']

    $config_hash['custom_setup_class'] = $custom_setup_class
    $allowed_hosts = '%'
    #$allowed_hosts = 'localhost'
    $rep_user = 'replicator'
    $rep_pass = 'replicant666'


#    class {'mysql::server::vip':
#      vip_address => '192.168.1.250',
#      prefix      => '24'
#    }


    create_resources( 'class', { 'mysql::config' => $config_hash } )

    if !defined(Package[mysql-client]) {
      package { 'mysql-client':
        name   => $package_name,
      }
    }

    package { 'mysql-server':
      name   => $package_name,
    }

    mysql::replicator { $allowed_hosts:
      user      => $rep_user,
      password  => $rep_pass,
      require   => Exec['mysqld-restart'],
      before    => Service['mysqld_stopped']
    }
    mysql::replicator { 'localhost':
      user      => $rep_user,
      password  => $rep_pass,
      require   => Exec['mysqld-restart'],
      before    => Service['mysqld_stopped']
    }


    service { 'mysqld_stopped':
      name     => $service_name,
      ensure   => 'stopped',
      enable   => false,
      require  => Class['mysql::config'],
      #require  => Package['mysql-server'],
      #provider => $service_provider,
    }
    Service['mysqld_stopped'] -> Service['mysqld']

    #if !defined(Class['openstack::corosync']) {
    #  class {'openstack::corosync' :
    #    bind_address => $galera_node_address,
    #  }
    #}
    Service['mysqld_stopped'] -> Class['openstack::corosync']
 
    Class['openstack::corosync'] -> Cs_resource['p_mysql']

#    cs_shadow { 'mysqlvip' : cib => 'mysqlvip' } ->
#    cs_resource { 'mysql_vip':
#      primitive_class => 'ocf',
#      primitive_type  => 'IPaddr2',
#      provided_by     => 'heartbeat',
#      parameters      => { 'ip' => $galera_node_address, 'cidr_netmask' => '24',
#                           'no-quorum-policy' => 'ignore' },
#      operations      => { 'monitor' => { 'interval' => '15s' } },
#    }->
#
#    #cs_rsc_defaults { "resource-stickiness":
#    #  ensure => present,
#    #  value  => '110',
#    #}->
#    cs_commit { 'mysqlvip' : cib => "mysqlvip" } ->


    cs_shadow { 'mysql': cib => 'mysql' } ->
    cs_resource { "p_mysql":
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'heartbeat',
      primitive_type  => 'mysql',
      cib             => 'mysql',
      multistate_hash => {'type'=>'master'},
      ms_metadata     => {'notify'=>"true"},
      parameters      => {
        'binary' => "/usr/bin/mysqld_safe",
        'test_table'         => 'mysql.user',
        'replication_user'   => $rep_user,
        'replication_passwd' => $rep_pass
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
      require  => Package['mysql-server'],
      provider => 'pacemaker',
    }

    #Tie internal-vip to p_mysql
    cs_colocation { 'mysql_to_internal-vip': 
      primitives => ['internal-vip','p_mysql'],
      require => [Cs_resource['internal-vip'],Cs_commit['mysql']],
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
#    require($galera_class)
  }
  
   else {
    require($custom_setup_class)
  }
}
