# Private class
define haproxy::service (
  $order       = '20',
  $content     = '',
  $use_include = $haproxy::params::use_include,
) {

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

  if $use_include {
    $target         = "/etc/haproxy/conf.d/${order}-${name}.cfg"
    $fragment_order = '00'

    concat { $target:
      owner  => '0',
      group  => '0',
      mode   => '0644',
    }

  } else {
    $target         = '/etc/haproxy/haproxy.cfg'
    $fragment_order = "${order}-${name}-00"
  }

  concat::fragment { "haproxy_${name}":
    ensure  => $ensure,
    order   => $fragment_order,
    target  => $target,
    content => $content,
  }
}
