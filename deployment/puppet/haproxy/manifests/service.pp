# Private class
class haproxy::service inherits haproxy {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  if $_service_manage {
    if ($::osfamily == 'Debian') {
      file { '/etc/default/haproxy':
        content => 'ENABLED=1',
        before  => Service['haproxy'],
      }
    }

    service { 'haproxy':
      ensure     => $_service_ensure,
      enable     => $_service_ensure ? {
        'running' => true,
        'stopped' => false,
        default   => $_service_ensure,
      },
      name       => 'haproxy',
      hasrestart => true,
      hasstatus  => true,
      restart    => $restart_command,
    }
  }
}
