# Private class
class haproxy::service inherits haproxy {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  if $haproxy::_service_manage {
    if ($::osfamily == 'Debian') {
      file { '/etc/default/haproxy':
        content => 'ENABLED=1',
        before  => Service['haproxy'],
      }
    }

    $_service_enable = $haproxy::_service_ensure ? {
      'running' => true,
      'stopped' => false,
      default   => $haproxy::_service_ensure,
    }

    service { 'haproxy':
      ensure     => $haproxy::_service_ensure,
      enable     => $_service_enable,
      name       => 'haproxy',
      hasrestart => true,
      hasstatus  => true,
      restart    => $haproxy::restart_command,
    }
  }
}
