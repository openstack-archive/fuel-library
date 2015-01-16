# Private class
class haproxy::config inherits haproxy {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  concat { '/etc/haproxy/haproxy.cfg':
    owner   => '0',
    group   => '0',
    mode    => '0644',
  }

  # Simple Header
  concat::fragment { '00-header':
    target  => '/etc/haproxy/haproxy.cfg',
    order   => '01',
    content => "# This file managed by Puppet\n",
  }

  # Template uses $global_options, $defaults_options
  concat::fragment { 'haproxy-base':
    target  => '/etc/haproxy/haproxy.cfg',
    order   => '10',
    content => template('haproxy/haproxy-base.cfg.erb'),
  }

  if $global_options['chroot'] {
    file { $global_options['chroot']:
      ensure => directory,
      owner  => $global_options['user'],
      group  => $global_options['group'],
    }
  }
}
