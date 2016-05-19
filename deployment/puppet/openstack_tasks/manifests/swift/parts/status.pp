class openstack_tasks::swift::parts::status (
  $address     = '0.0.0.0',
  $only_from   = '127.0.0.1',
  $port        = '49001',
  $endpoint    = 'http://127.0.0.1:8080',
  $scan_target = '127.0.0.1:5000',
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
    'RedHat' => 'nobody',
    'Debian' => 'nogroup',
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
    server_args => "${endpoint} ${scan_target} ${con_timeout}",
    user        => 'nobody',
    group       => $group,
    flags       => 'IPv4',
    require     => Augeas['swiftcheck'],
  }
}
