# Base configuration of HAProxy for OpenStack
class openstack::ha::haproxy_base (
  $global_options   = $haproxy::params::global_options,
  $defaults_options = $haproxy::params::defaults_options,
) inherits ::haproxy::params {

  concat { '/etc/haproxy/haproxy.cfg':
    owner   => '0',
    group   => '0',
    mode    => '0644',
  }

  # Simple Header
  concat::fragment { '00-header':
    target  => '/etc/haproxy/haproxy.cfg',
    order   => '01',
    content => "# This file is managed by Puppet\n",
  }

  # Template uses $global_options, $defaults_options
  concat::fragment { 'haproxy-base':
    target  => '/etc/haproxy/haproxy.cfg',
    order   => '10',
    content => template('haproxy/haproxy-base.cfg.erb'),
  }
}
