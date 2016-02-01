# == Class: openstack::galera::status
#
# Configures a user and script that will check the status
# of galera cluster, assumes mysql module is in catalog
#
# === Parameters:
#
# [*address*]
# (optional) xinet.d bind address for clustercheck
# Defaults to 0.0.0.0
#
# [*only_from*]
# (optional) xinet.d only_from address for swiftcheck
# Defaults to 127.0.0.1
#
# [*status_user*]
# (optiona) The name of user to use for status checks
# Defaults to false
#
# [*status_password*]
# (optional) The password of the status check user
# Defaults to false
#
# [*status_allow*]
# (optional) The subnet to allow status checks from
# Defaults to '%'
#
# [*port*]
# (optional) Port for cluster check service
# Defaults to 49000
#
# [*backend_host*]
#  (optional) The MySQL backend host for cluster check
#  Defaults to 127.0.0.1
#
# [*backend_port*]
#  (optional) The MySQL backend port for cluster check
#  Defaults to 3306
#
# [*backend_timeout*]
#  (optional) The timeout for MySQL backend connection for cluster check
#  Defaults to 10 seconds
#

class openstack::galera::status (
  $address         = '0.0.0.0',
  $only_from       = '127.0.0.1',
  $status_user     = false,
  $status_password = false,
  $status_allow    = '%',
  $port            = '49000',
  $backend_host    = '127.0.0.1',
  $backend_port    = '3306',
  $backend_timeout = '10',
) {

  validate_string($status_user, $status_password)

  mysql_user { "${status_user}@${status_allow}":
    ensure        => 'present',
    password_hash => mysql_password($status_password),
    require       => [File["${::root_home}/.my.cnf"],Service['mysqld']],
  } ->
  mysql_grant { "${status_user}@${status_allow}/*.*":
    ensure     => 'present',
    options    => [ 'GRANT' ],
    privileges => [ 'USAGE' ],
    table      => '*.*',
    user       => "${status_user}@${status_allow}",
    before     => Anchor['mysql::server::end'],
  }

  file { '/etc/wsrepclustercheckrc':
    content => template('openstack/galera_clustercheck.erb'),
    owner   => 'nobody',
    group   => 'nogroup',
    mode    => '0400',
    before  => Anchor['mysql::server::end'],
  }

  augeas { 'galeracheck':
    context => '/files/etc/services',
    changes => [
      "set /files/etc/services/service-name[port = '${port}']/port ${port}",
      "set /files/etc/services/service-name[port = '${port}'] galeracheck",
      "set /files/etc/services/service-name[port = '${port}']/protocol tcp",
      "set /files/etc/services/service-name[port = '${port}']/#comment 'Galera Cluster Check'",
    ],
    before  => Anchor['mysql::server::end'],
  }

  $group = $::osfamily ? {
    'redhat' => 'nobody',
    'debian' => 'nogroup',
    default  => 'nobody',
  }

  include ::xinetd
  xinetd::service { 'galeracheck':
    bind       => $address,
    port       => $port,
    only_from  => $only_from,
    cps        => '512 10',
    per_source => 'UNLIMITED',
    server     => '/usr/bin/galeracheck',
    user       => 'nobody',
    group      => $group,
    flags      => 'IPv4',
    require    => Augeas['galeracheck'],
    before     => Anchor['mysql::server::end'],
  }
}
