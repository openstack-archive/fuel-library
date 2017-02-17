# == Class: cluster::galera_status
#
# Configures a script that will check the status
# of galera cluster
#
# === Parameters:
#
# [*status_user*]
#  (required). String. Mysql user to use for connection testing and status
#  checks.
#
# [*status_password*]
#  (required). String. Password for the mysql user to check with.
#
# [*address*]
# (optional) xinet.d bind address for clustercheck
# Defaults to 0.0.0.0
#
# [*only_from*]
# (optional) xinet.d only_from address for swiftcheck
# Defaults to 127.0.0.1
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

class cluster::galera_status (
  $status_user,
  $status_password,
  $address         = '0.0.0.0',
  $only_from       = '127.0.0.1',
  $port            = '49000',
  $backend_host    = '127.0.0.1',
  $backend_port    = '3306',
  $backend_timeout = '10',
) {

  $group = $::osfamily ? {
    'redhat' => 'nobody',
    'debian' => 'nogroup',
    default  => 'nobody',
  }

  file { '/etc/wsrepclustercheckrc':
    content => template('openstack/galera_clustercheck.erb'),
    owner   => 'nobody',
    group   => $group,
    mode    => '0400',
    require => Anchor['mysql::server::end'],
  }

  augeas { 'galeracheck':
    context => '/files/etc/services',
    changes => [
      "set /files/etc/services/service-name[port = '${port}']/port ${port}",
      "set /files/etc/services/service-name[port = '${port}'] galeracheck",
      "set /files/etc/services/service-name[port = '${port}']/protocol tcp",
      "set /files/etc/services/service-name[port = '${port}']/#comment 'Galera Cluster Check'",
    ],
    require => Anchor['mysql::server::end'],
  }

  contain ::xinetd
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
    require    => [ Augeas['galeracheck'],
                    Anchor['mysql::server::end']],
  }
}
