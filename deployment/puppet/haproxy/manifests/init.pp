# == Class: puppet-haproxy
#
# A Puppet module, using storeconfigs, to model an haproxy configuration.
# Currently VERY limited - assumes Redhat/CentOS setup. Pull requests accepted!
#
# === Requirement/Dependencies:
#
# Currently requires the ripienaar/concat module on the Puppet Forge and
#  uses storeconfigs on the Puppet Master to export/collect resources
#  from all balancer members.
#
# === Parameters
#
# [*enable*]
#   Chooses whether haproxy should be installed or ensured absent.
#   Currently ONLY accepts valid boolean true/false values.
#
# [*haproxy_global_options*]
#   A hash of all the haproxy global options. If you want to specify more
#    than one option (i.e. multiple timeout or stats options), pass those
#    options as an array and you will get a line for each of them in the
#    resultant haproxy.cfg file.
#
# [*haproxy_defaults_options*]
#   A hash of all the haproxy defaults options. If you want to specify more
#    than one option (i.e. multiple timeout or stats options), pass those
#    options as an array and you will get a line for each of them in the
#    resultant haproxy.cfg file.
#
#
# === Examples
#
#  class { 'haproxy':
#      enable                   => true,
#      haproxy_global_options   => { 'log'     => "${::ipaddress} local0",
#                                   'chroot'  => '/var/lib/haproxy',
#                                   'pidfile' => '/var/run/haproxy.pid',
#                                   'maxconn' => '4000',
#                                   'user'    => 'haproxy',
#                                   'group'   => 'haproxy',
#                                   'daemon'  => '',
#                                   'stats'   => 'socket /var/lib/haproxy/stats'
#                                 },
#      haproxy_defaults_options => { 'log'     => 'global',
#                                    'stats'   => 'enable',
#                                    'option'  => 'redispatch',
#                                    'retries' => '3',
#                                    'timeout' => ['http-request 10s',
#                                                 'queue 1m',
#                                                 'connect 10s',
#                                                 'client 1m',
#                                                 'server 1m',
#                                                 'check 10s'],
#                                    'maxconn' => '8000'
#                                  },
#
#  }
#
# === Authors
#
# Gary Larizza <gary@puppetlabs.com>
#
class haproxy (
  $enable                   = true,
  $haproxy_global_options   = $haproxy::data::haproxy_global_options,
  $haproxy_defaults_options = $haproxy::data::haproxy_defaults_options
) inherits haproxy::data {
  include concat::setup

  package { 'haproxy':
    ensure  => $enable ? {
      true  => present,
      false => absent,
    },
    name    => 'haproxy',
  }

  if $enable {
    concat { '/etc/haproxy/haproxy.cfg':
      owner   => '0',
      group   => '0',
      mode    => '0644',
      require => Package['haproxy'],
      notify  => Service['haproxy'],
    }

    # Simple Header
    concat::fragment { '00-header':
      target  => '/etc/haproxy/haproxy.cfg',
      order   => '01',
      content => "# This file managed by Puppet\n",
    }

    # Most of the variables are used inside the haproxy-base.cfg.erb template
    concat::fragment { 'haproxy-base':
      target  => '/etc/haproxy/haproxy.cfg',
      order   => '10',
      content => template('haproxy/haproxy-base.cfg.erb'),
    }
  }

  service { 'haproxy':
    ensure     => $enable ? {
      true  => running,
      false => stopped,
    },
    enable     => $enable ? {
      true  => true,
      false => false,
    },
    name       => 'haproxy',
    hasrestart => true,
    hasstatus  => true,
    require    => [File['/var/lib/haproxy'], Concat['/etc/haproxy/haproxy.cfg']],
  }

  file { '/etc/default/haproxy':
    content => $enable ? {
      true  => "ENABLED=1",
      false => "ENABLED=0",
    },
    require => Service['haproxy']
  }

  file { '/var/lib/haproxy':
    ensure => directory,
  }
}
