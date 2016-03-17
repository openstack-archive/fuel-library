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
)
  inherits cgroups::params
{
  validate_hash($cgroups_set)
  ensure_packages($packages)

  File {
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { '/etc/cgconfig.conf':
    content => template('cgroups/cgconfig.conf.erb'),
  }

  file { '/etc/cgrules.conf':
    content => template('cgroups/cgrules.conf.erb'),
  }

  class { '::cgroups::service':
    cgroups_settings => $cgroups_set,
  }

  File['/etc/cgconfig.conf'] ~> Service['cgrulesengd']

  Package<||> ->
  File<||> ->
  Service['cgroup-lite'] ->
  Service['cgconfigparser'] ->
  Cgclassify<||> ->
  Service['cgrulesengd']
}
