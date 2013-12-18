# Class: qpid::server
#
# This module manages the installation and config of the qpid server.
class qpid::server(
  $package_ensure = present,
  $service_ensure = running,

  $qpid_port = '5672',
  $auth = 'no',
  $auth_realm = 'QPID',
  $log_to_file = 'UNSET',
  $cluster_mechanism = 'DIGEST-MD5 ANONYMOUS',

  $qpid_cluster = false,
  $qpid_cluster_name = 'qpid_cluster',
  $qpid_username = 'nova',
  $qpid_password = 'nova',
  $qpid_nodes = [$::ipaddress],
) {

  validate_re($auth, '^(yes$|no$)')

  include qpid::params
  include stdlib
  package { $::qpid::params::package_name:
    ensure => $package_ensure,
  }

  define qpid_safe_package(){
    if ! defined(Package[$name]){
      @package { $name : }
    }
  }


  if size($qpid_nodes) > 1 {
    package { [$qpid::params::additional_packages]:
      ensure => $package_ensure,
    }
    qpid_safe_package { $qpid::params::additional_packages : }
    #Disable routing because it creates duplicates. Need upstream fixes
#    file { '/usr/local/bin/qpid-setup-routes.sh':
#      ensure  => present,
#      owner   => 'root',
#      group   => 'root',
#      mode    => '0755',
#      content => template('qpid/qpid-setup-routes.sh.erb'),
#    }
#
#    exec { "propagate_qpid_routes":
#      path      => "/usr/bin/:/bin:/usr/sbin",
#      command   => "bash /usr/local/bin/qpid-setup-routes.sh",
#      subscribe => File['/usr/local/bin/qpid-setup-routes.sh'],
#      logoutput => true,
#    }
  }
  if $auth == 'yes' {
    qpid_user { 'qpid_user':
      password => $qpid_password,
      file => '/var/lib/qpidd/qpidd.sasldb',
      realm => $auth_realm,
      name => $qpid_username,
      provider => 'saslpasswd2',
      require => Package[$::qpid::params::package_name],
    } ->

    file {'/var/lib/qpidd/qpidd.sasldb':
      ensure => present,
      owner  => 'qpidd',
      group  => 'qpidd',
      mode   => '0600',
      before => File[$::qpid::params::config_file]
    }
  }
  file { $::qpid::params::config_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('qpid/qpidd.conf.erb'),
    require => Package[$::qpid::params::package_name],
  }

  if $log_to_file != 'UNSET' {
    file { $log_to_file:
      ensure  => present,
      owner   => 'qpidd',
      group   => 'qpidd',
      mode    => '0644',
      require => Package[$::qpid::params::package_name],
      before  => File[$::qpid::params::config_file],
    }
  }
    service { $::qpid::params::service_name:
      enable => true,
      ensure => $service_ensure,
      hasstatus  => true,
      hasrestart => true,
      require => [Package[$::qpid::params::package_name], File[$::qpid::params::config_file]],
    }

}


