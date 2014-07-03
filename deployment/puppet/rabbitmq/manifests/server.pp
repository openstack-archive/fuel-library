# Class: rabbitmq::server
#
# This module manages the installation and config of the rabbitmq server
#   it has only been tested on certain version of debian-ish systems
# Parameters:
#  [*port*] - port where rabbitmq server is hosted
#  [*delete_guest_user*] - rather or not to delete the default user
#  [*version*] - version of rabbitmq-server to install
#  [*package_name*] - name of rabbitmq package
#  [*service_name*] - name of rabbitmq service
#  [*service_ensure*] - desired ensure state for service
#  [*stomp_port*] - port stomp should be listening on
#  [*node_ip_address*] - ip address for rabbitmq to bind to
#  [*config*] - contents of config file
#  [*env_config*] - contents of env-config file
#  [*config_cluster*] - whether to configure a RabbitMQ cluster
#  [*cluster_disk_nodes*] - which nodes to cluster with (including the current one)
#  [*erlang_cookie*] - erlang cookie, must be the same for all nodes in a cluster
#  [*wipe_db_on_cookie_change*] - whether to wipe the RabbitMQ data if the specified
#    erlang_cookie differs from the current one. This is a sad parameter: actually,
#    if the cookie indeed differs, then wiping the database is the *only* thing you
#    can do. You're only required to set this parameter to true as a sign that you
#    realise this.

# Requires:
#  stdlib
# Sample Usage:
#
#
#
#
# [Remember: No empty lines between comments and class definition]
class rabbitmq::server(
  $production = 'prod',
  $port = '5672',
  $delete_guest_user = false,
  $package_name = 'rabbitmq-server',
  $version = 'UNSET',
  $service_name = 'rabbitmq-server',
  $service_ensure = 'running',
  $service_enabled = true,
  $config_stomp = false,
  $stomp_port = '6163',
  $config_cluster = false,
  $cluster_disk_nodes = [],
  $node_ip_address = 'UNSET', #getvar("::ipaddress_${::internal_interface}"),
  $config='UNSET',
  $env_config='UNSET',
  $erlang_cookie='EOKOWXQREETZSHFNTPEY',
  $wipe_db_on_cookie_change=true,
  $inet_dist_listen_min = '41055',
  $inet_dist_listen_max = '41055',
  $max_retry = '60',
  $service_provider = undef
) {

  validate_bool($delete_guest_user, $config_stomp)
  validate_re($port, '\d+')
  validate_re($stomp_port, '\d+')

  if $version == 'UNSET' {
    $version_real = '2.4.1'
    $pkg_ensure_real   = 'present'
  } else {
    $version_real = $version
    $pkg_ensure_real   = $version
  }
  if $config == 'UNSET' {
    $config_real = template("${module_name}/rabbitmq.config")
  } else {
    $config_real = $config
  }
  if $env_config == 'UNSET' {
    $env_config_real = template("${module_name}/rabbitmq-env.conf.erb")
  } else {
    $env_config_real = $env_config
  }

  $plugin_dir = "/usr/lib/rabbitmq/lib/rabbitmq_server-${version_real}/plugins"

  if $::osfamily == 'RedHat' {
    package {'qpid-cpp-server': ensure => 'purged' }
    Package['qpid-cpp-server'] -> Package[$package_name]
  }

  package { $package_name:
    ensure => $pkg_ensure_real,
    notify => Class['rabbitmq::service'],
  }

  file { '/etc/rabbitmq':
    ensure  => directory,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    require => Package[$package_name],
  }

  file { 'rabbitmq.config':
    ensure  => file,
    path    => '/etc/rabbitmq/rabbitmq.config',
    content => $config_real,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    require => Package[$package_name],
    notify  => Class['rabbitmq::service'],
  }

  if $config_cluster {
     file { 'erlang_cookie':
       path =>"/var/lib/rabbitmq/.erlang.cookie",
       owner   => rabbitmq,
       group   => rabbitmq,
       mode    => '0400',
       content => $erlang_cookie,
       replace => true,
       before  => File['rabbitmq.config'],
       require => Exec['wipe_db'], # require => Exec['rabbitmq_stop']
     }
     # require authorize_cookie_change

     if $wipe_db_on_cookie_change {
       exec { 'wipe_db':
         command => '/etc/init.d/rabbitmq-server stop; /bin/rm -rf /var/lib/rabbitmq/mnesia',
         require => Package[$package_name],
         unless  => "/bin/grep -qx ${erlang_cookie} /var/lib/rabbitmq/.erlang.cookie"
       }
     } else {
       exec { 'wipe_db':
         command => '/bin/false "Cookie must be changed but wipe_db is false"', # If the cookie doesn't match, just fail.
         require => Package[$package_name],
         unless  => "/bin/grep -qx ${erlang_cookie} /var/lib/rabbitmq/.erlang.cookie"
       }
     }
   }

  file { 'rabbitmq-env.config':
    ensure  => file,
    path    => '/etc/rabbitmq/rabbitmq-env.conf',
    content => $env_config_real,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    notify  => Class['rabbitmq::service'],
  }
  if $production !~ /docker/ {
    case $::osfamily {
      'RedHat' : {
        file { 'rabbitmq-server':
          ensure  => present,
          path    => '/etc/init.d/rabbitmq-server',
          content => template('rabbitmq/rabbitmq-server_redhat.erb'),
          replace => true,
          owner   => '0',
          group   => '0',
          mode    => '0755',
          #notify  => Class['rabbitmq::service'],
          require => Package[$package_name],
        }
      }
      'Debian' : {
        file { 'rabbitmq-server':
          ensure  => present,
          path    => '/etc/init.d/rabbitmq-server',
          content => template('rabbitmq/rabbitmq-server_ubuntu.erb'),
          replace => true,
          owner   => '0',
          group   => '0',
          mode    => '0755',
          #notify  => Class['rabbitmq::service'],
          require => Package[$package_name],
        }
      }
    }
  }
  class { 'rabbitmq::service':
    service_name     => $service_name,
    ensure           => $service_ensure,
    enabled          => $service_enabled,
    service_provider => $service_provider
  }

  if $delete_guest_user {
    # delete the default guest user
    rabbitmq_user{ 'guest':
      ensure   => absent,
      provider => 'rabbitmqctl',
    }
  }

}
