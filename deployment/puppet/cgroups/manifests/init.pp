# == Class: cgroups
#
# CGroups is a Linux kernel feature that manage the resource usage (CPU, memory,
# disk I/O, network, etc.) of a collection of processes.
#
# === Parameters
#
# [*cgroups_set*]
#   (required) Hiera hash with cgroups settings
# [*packages*]
#   (required) Names of packages for CGroups
#
class cgroups(
  $cgroups_set = {},
  $packages    = $cgroups::params::packages,
) inherits cgroups::params {

  validate_hash($cgroups_set)
  ensure_packages($packages, { tag => 'cgroups' })

  File {
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service['cgconfig'],
  }

  file { '/etc/cgconfig.conf':
    content => template('cgroups/cgconfig.conf.erb'),
    tag     => 'cgroups',
  }

  file { '/etc/cgrules.conf':
    content => template('cgroups/cgrules.conf.erb'),
    tag     => 'cgroups',
  }

  file { '/etc/init.d/cgconfig':
    mode   => '0755',
    source => "puppet:///modules/${module_name}/cgconfig.init",
    tag    => 'cgroups',
  }

  class { '::cgroups::service':
    cgroups_settings => $cgroups_set,
  }

  Package <| tag == 'cgroups' |> -> File <| tag == 'cgroups' |>
  Service['cgconfig'] -> Cgclassify <||>

}
