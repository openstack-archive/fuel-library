# Private class
class haproxy::config inherits haproxy {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  concat { $haproxy::config_file:
    owner => '0',
    group => '0',
    mode  => '0644',
  }

  # Simple Header
  concat::fragment { '00-header':
    target  => $haproxy::config_file,
    order   => '01',
    content => "# This file managed by Puppet\n",
  }

  # Template uses $global_options, $defaults_options
  concat::fragment { 'haproxy-base':
    target  => $haproxy::config_file,
    order   => '10',
    content => template('haproxy/haproxy-base.cfg.erb'),
  }

  if $haproxy::global_options['chroot'] {
    file { $haproxy::global_options['chroot']:
      ensure => directory,
      owner  => $haproxy::global_options['user'],
      group  => $haproxy::global_options['group'],
    }
  }
}
