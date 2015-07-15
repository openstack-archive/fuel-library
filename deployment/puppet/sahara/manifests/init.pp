# == Class: sahara
#
#  Sahara base package & configuration
#
# === Parameters
#
# [*package_ensure*]
#   (Optional) Ensure state for package
#   Defaults to 'present'.
#
# [*manage_service*]
#   (optional) Whether the service should be managed by Puppet.
#   Defaults to true.
#
# [*enabled*]
#   (optional) Should the service be enabled.
#   Defaults to true.
#
# [*verbose*]
#   (Optional) Should the daemons log verbose messages
#   Defaults to 'false'.
#
# [*debug*]
#   (Optional) Should the daemons log debug messages
#   Defaults to 'false'.
#
# [*use_syslog*]
#   Use syslog for logging.
#   (Optional) Defaults to false.
#
# [*log_facility*]
#   Syslog facility to receive log lines.
#   (Optional) Defaults to LOG_USER.
#
# [*log_dir*]
#   (optional) Directory where logs should be stored.
#   If set to boolean false, it will not log to any directory.
#   Defaults to '/var/log/sahara'
#
# [*service_host*]
#   (Optional) Hostname for sahara to listen on
#   Defaults to '0.0.0.0'.
#
# [*service_port*]
#   (Optional) Port for sahara to listen on
#   Defaults to 8386.
#
# [*use_neutron*]
#   (Optional) Whether to use neutron
#   Defaults to 'false'.
#
# [*use_floating_ips*]
#   (Optional) Whether to use floating IPs to communicate with instances.
#   Defaults to 'true'.
#
# [*database_connection*]
#   (Optional) Non-sqllite database for sahara
#   Defaults to 'mysql://sahara:secrete@localhost:3306/sahara'
#
# == keystone authentication options
#
# [*keystone_username*]
#   (Optional) Username for sahara credentials
#   Defaults to 'admin'.
#
# [*keystone_password*]
#   (Optional) Password for sahara credentials
#   Defaults to false.
#
# [*keystone_tenant*]
#   (Optional) Tenant for keystone_username
#   Defaults to 'admin'.
#
# [*keystone_url*]
#   (Optional) Public identity endpoint
#   Defaults to 'http://127.0.0.1:5000/v2.0/'.
#
# [*identity_url*]
#   (Optional) Admin identity endpoint
#   Defaults to 'http://127.0.0.1:35357/'.
#
class sahara(
  $manage_service      = true,
  $enabled             = true,
  $package_ensure      = 'present',
  $verbose             = false,
  $debug               = false,
  $use_syslog          = false,
  $log_facility        = 'LOG_USER',
  $log_dir             = '/var/log/sahara',
  $service_host        = '0.0.0.0',
  $service_port        = 8386,
  $use_neutron         = false,
  $use_floating_ips    = true,
  $database_connection = 'mysql://sahara:secrete@localhost:3306/sahara',
  $keystone_username   = 'admin',
  $keystone_password   = false,
  $keystone_tenant     = 'admin',
  $keystone_url        = 'http://127.0.0.1:5000/v2.0/',
  $identity_url        = 'http://127.0.0.1:35357/',
) {
  include ::sahara::params
  include ::sahara::policy

  if $::osfamily == 'RedHat' {
    $group_require = Package['sahara']
    $dir_require = Package['sahara']
    $conf_require = Package['sahara']
  } else {
    # TO-DO(mmagr): This hack has to be removed as soon as following bug
    # is fixed. On Ubuntu sahara-trove is not installable because it needs
    # running database and prefilled sahara.conf in order to install package:
    # https://bugs.launchpad.net/ubuntu/+source/sahara/+bug/1452698
    Sahara_config<| |> -> Package['sahara']

    $group_require = undef
    $dir_require = Group['sahara']
    $conf_require = File['/etc/sahara']
  }
  group { 'sahara':
    ensure  => 'present',
    name    => 'sahara',
    system  => true,
    require => $group_require
  }

  user { 'sahara':
    ensure  => 'present',
    gid     => 'sahara',
    system  => true,
    require => Group['sahara']
  }

  file { '/etc/sahara/':
    ensure                  => directory,
    owner                   => 'root',
    group                   => 'sahara',
    require                 => $dir_require,
    selinux_ignore_defaults => true
  }

  file { '/etc/sahara/sahara.conf':
    owner                   => 'root',
    group                   => 'sahara',
    require                 => $conf_require,
    selinux_ignore_defaults => true
  }

  package { 'sahara':
    ensure => $package_ensure,
    name   => $::sahara::params::package_name,
    tag    => 'openstack',
  }

  # Because Sahara does not support SQLite, sahara-common will fail to be installed
  # if /etc/sahara/sahara.conf does not contain valid database connection and if the
  # database does not actually exist.
  # So we first manage the configuration file existence, then we configure Sahara and
  # then we install Sahara. This is a very ugly hack to fix packaging issue.
  # https://bugs.launchpad.net/cloud-archive/+bug/1450945
  File['/etc/sahara/sahara.conf'] -> Sahara_config<| |>

  Package['sahara'] -> Class['sahara::policy']

  Package['sahara'] ~> Service['sahara']
  Class['sahara::policy'] ~> Service['sahara']

  validate_re($database_connection, '(sqlite|mysql|postgresql):\/\/(\S+:\S+@\S+\/\S+)?')

  case $database_connection {
    /^mysql:\/\//: {
      require mysql::bindings
      require mysql::bindings::python
    }
    /^postgresql:\/\//: {
      require postgresql::lib::python
    }
    /^sqlite:\/\//: {
      fail('Sahara does not support sqlite!')
    }
    default: {
      fail('Unsupported db backend configured')
    }
  }

  sahara_config {
    'DEFAULT/use_neutron': value => $use_neutron;
    'DEFAULT/use_floating_ips': value => $use_floating_ips;
    'DEFAULT/host': value => $service_host;
    'DEFAULT/port': value => $service_port;
    'DEFAULT/debug': value => $debug;
    'DEFAULT/verbose': value => $verbose;

    'database/connection':
      value => $database_connection,
      secret => true;
  }

  if $keystone_password {
    sahara_config {
      'keystone_authtoken/auth_uri': value => $keystone_url;
      'keystone_authtoken/identity_uri': value => $identity_url;
      'keystone_authtoken/admin_user': value => $keystone_username;
      'keystone_authtoken/admin_tenant_name': value => $keystone_tenant;
      'keystone_authtoken/admin_password':
        value => $keystone_password,
        secret => true;
    }
  }

  if $log_dir {
    sahara_config {
      'DEFAULT/log_dir': value => $log_dir;
    }
  } else {
    sahara_config {
      'DEFAULT/log_dir': ensure => absent;
    }
  }

  if $use_syslog {
    sahara_config {
      'DEFAULT/use_syslog':           value => true;
      'DEFAULT/syslog_log_facility':  value => $log_facility;
    }
  } else {
    sahara_config {
      'DEFAULT/use_syslog':           value => false;
    }
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  service { 'sahara':
    ensure     => $service_ensure,
    name       => $::sahara::params::service_name,
    hasstatus  => true,
    enable     => $enabled,
    hasrestart => true,
    subscribe  => Exec['sahara-dbmanage'],
  }

  exec { 'sahara-dbmanage':
    command     => $::sahara::params::dbmanage_command,
    path        => '/usr/bin',
    user        => 'sahara',
    refreshonly => true,
    subscribe   => [Package['sahara'], Sahara_config['database/connection']],
    logoutput   => on_failure,
  }

}
