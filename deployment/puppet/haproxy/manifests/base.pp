# == Class: haproxy::base
#
# This class will create haproxy.cfg and populate it with global and
#  defaults configuration sections.
#
# === Parameters
#
# [*global_options*]
#   A hash of all the haproxy global options. If you want to specify more
#    than one option (i.e. multiple timeout or stats options), pass those
#    options as an array and you will get a line for each of them in the
#    resultant haproxy.cfg file.
#
# [*defaults_options*]
#   A hash of all the haproxy defaults options. If you want to specify more
#    than one option (i.e. multiple timeout or stats options), pass those
#    options as an array and you will get a line for each of them in the
#    resultant haproxy.cfg file.
#
# [*use_include*]
#   Chooses whether include directive can be used to collect haproxy
#    configuration from multiple fragment files in a conf.d directory,
#    or all fragments have to be contatenated into a single haproxy.cfg.
#
class haproxy::base (
  $global_options   = $haproxy::params::global_options,
  $defaults_options = $haproxy::params::defaults_options,
  $use_include      = $haproxy::params::use_include,
  $use_stats        = $haproxy::params::use_stats,
  $stats_port       = $haproxy::params::stats_port,
  $stats_ipaddresses = $haproxy::params::stats_ipaddresses,
  $custom_fragment = undef,
) inherits haproxy::params {

  concat { '/etc/haproxy/haproxy.cfg':
    owner  => '0',
    group  => '0',
    mode   => '0644',
    before => Service['haproxy'],
  }

  # Simple Header
  concat::fragment { 'haproxy-header':
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
    }
  }

  if $use_stats {
    concat::fragment { 'haproxy-stats' :
      target  => '/etc/haproxy/haproxy.cfg',
      order   => '90',
      content => template('haproxy/haproxy-stats.cfg.erb'),
    }
  }

  if $use_include {
    concat::fragment { 'haproxy-include':
      target  => '/etc/haproxy/haproxy.cfg',
      order   => '99',
      content => "\ninclude conf.d/*.cfg\n",
    }

    file { '/etc/haproxy/conf.d':
      ensure => 'directory',
      owner  => '0',
      group  => '0',
    }
  }
}
