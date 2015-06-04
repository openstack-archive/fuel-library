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
# [*only_from*]
# (optional) xinet.d only_from address for swiftcheck
# Defaults to 127.0.0.1
#
# [*port*]
# (optional) Port for swift check service
# Defaults to 49001
#
# [*endpoint*]
#  (optional) The Swift endpoint host for swift healthcheck
#  Defaults to http://127.0.0.1:8080
#
# [*vip*]
#  (optional) The VIP address for the ICMP connectivity check
#  Defaults to 127.0.0.1
#
# [*con_timeout*]
#  (optional) The timeout for Swift endpoint connection for swift healthcheck
#  Defaults to 5 seconds
#

class openstack::swift::status (
  $address     = '0.0.0.0',
  $only_from   = '127.0.0.1',
  $port        = '49001',
  $endpoint    = 'http://127.0.0.1:8080',
  $vip         = '127.0.0.1',
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
    only_from   => $only_from,
    cps         => '512 10',
    per_source  => 'UNLIMITED',
    server      => '/usr/bin/swiftcheck',
    server_args => "${endpoint} ${vip} ${con_timeout}",
    user        => 'nobody',
    group       => $group,
    flags       => 'IPv4',
    require     => Augeas['swiftcheck'],
  }
}
