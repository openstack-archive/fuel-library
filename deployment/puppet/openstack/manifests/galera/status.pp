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
# [*mysql_module*]
#  (optional) The puppet-mysql module version to work with
#  Defaults to 0.9
#
# [*backend_port*]
#  (optional) The MySQL backend port for cluster check
#  Defaults to 3306
#
# [*backend_timeout*]
#  (optional) The timeout for MySQL backend connection for cluster check
#  Defaults to 10 seconds
#
# [*status_check*]
#  (optional) Either to perform MySQL backend status check or not
#  Defaults to False
#

class opensntack::galera::status (
  $address         = '0.0.0.0',
  $status_user     = false,
  $status_password = false,
  $status_allow    = '%',
  $port            = '49000',
  $mysql_module    = '0.9',
  $backend_host    = '127.0.0.1',
  $backend_port    = '3306',
  $backend_timeout = '10',
) {

  validate_string($status_user, $status_password)

  if ($mysql_module >= 2.2) {
    mysql_user { "${status_user}@${status_allow}":
      ensure        => 'present',
      password_hash => mysql_password($status_password),
      require       => Class['mysql::server'],
    } ->
    mysql_grant { "${status_user}@${status_allow}/*.*":
      ensure     => 'present',
      option     => [ 'GRANT' ],
      privileges => [ 'STATUS' ],
      table      => '*.*',
      user       => "${status_user}@${status_allow}",
    }
  } else {
    database_user { "${status_user}@${status_allow}":
      ensure        => 'present',
      password_hash => mysql_password($status_password),
      provider      => 'mysql',
      require       => Class['mysql::server'],
    } ->
    database_grant { "${status_user}@${status_allow}/*.*":
      privileges => [ 'Status_priv' ],
    }
  }

  file { '/usr/local/bin/clustercheck':
    content => template('openstack/galera_clustercheck.erb'),
    mode    => '0755',
  }

  augeas { 'galeracheck':
    context => '/files/etc/services',
    changes => [
      "set /files/etc/services/service-name[port = '${port}']/port ${port}",
      "set /files/etc/services/service-name[port = '${port}'] galeracheck",
      "set /files/etc/services/service-name[port = '${port}']/protocol tcp",
      "set /files/etc/services/service-name[port = '${port}']/#comment 'Galera Cluster Check'",
    ],
    require => File['/usr/local/bin/clustercheck'],
  }

  $group = $::osfamily ? {
    'redhat' => 'nobody',
    'debian' => 'nogroup',
    default  => 'nobody',
  }

  include xinetd
  xinetd::service { 'galeracheck':
    bind       => $address,
    port       => $port,
    cps        => '512 10',
    per_source => 'UNLIMITED',
    server     => '/usr/local/bin/clustercheck',
    user       => 'nobody',
    group      => $group,
    flags      => 'IPv4',
    require    => File['/usr/local/bin/clustercheck'],
  }
}
