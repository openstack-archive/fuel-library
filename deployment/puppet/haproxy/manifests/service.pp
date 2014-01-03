# == Class: haproxy::service
#
# This class will add a configuration block for a service either into
#  haproxy.cfg or as a separate file under a conf.d directory, depending
#  on the $use_include flag.
#
# If a separate file is created, it will be registered as a concat
#  target that balancermember entries can be added to.
#
# === Parameters
#
# [*order*]
#   Allows to override the relative order of services. If changed from
#    default, the order string of a listening service must exactly match
#    the order string of all balancermembers for that server.
#
# [*use_include*]
#   Chooses whether include directive can be used to collect haproxy
#    configuration from multiple fragment files in a conf.d directory,
#    or all fragments have to be contatenated into a single haproxy.cfg.
#
define haproxy::service (
  $ensure      = 'present',
  $order       = '20',
  $content     = '',
  $use_include = $haproxy::params::use_include,
) {

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
