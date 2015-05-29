# == Class: openstack::swift::status
#
# Configures a script that will check the health
# of swift proxy backend via given endpoint, assumes swift module is in catalog
#
# === Parameters:
#
# [*address*]
# (optional) xinet.d bind address for swiftcheck
# Defaults to 0.0.0.0
#
# [*port*]
# (optional) Port for swift check service
# Defaults to 49001
#
# [*endpoint*]
#  (optional) The Swift endpoint host for swift healthcheck
#  Defaults to http://127.0.0.1:8080
#
# [*con_timeout*]
#  (optional) The timeout for Swift endpoint connection for swift healthcheck
#  Defaults to 5 seconds
#

class openstack::swift::status (
  $address     = '0.0.0.0',
  $port        = '49001',
  $endpoint    = 'http://127.0.0.1:8080',
  $con_timeout = '5',
) {

  augeas { 'swiftcheck':
    context => '/files/etc/services',
    changes => [
      "set /files/etc/services/service-name[port = '${port}']/port ${port}",
      "set /files/etc/services/service-name[port = '${port}'] swiftcheck",
      "set /files/etc/services/service-name[port = '${port}']/protocol tcp",
      "set /files/etc/services/service-name[port = '${port}']/#comment 'Swift Health Check'",
    ],
  }

  $group = $::osfamily ? {
    'redhat' => 'nobody',
    'debian' => 'nogroup',
    default  => 'nobody',
  }

  include xinetd
  xinetd::service { 'swiftcheck':
    bind        => $address,
    port        => $port,
    cps         => '512 10',
    per_source  => 'UNLIMITED',
    server      => '/usr/bin/swiftcheck',
    server_args => "${endpoint} ${con_timeout}",
    user        => 'nobody',
    group       => $group,
    flags       => 'IPv4',
  }
}
