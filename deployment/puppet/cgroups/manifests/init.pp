# == Class: cgroups
#
# CGroups is a Linux kernel feature that limits, accounts for, and isolates
# the resource usage (CPU, memory, disk I/O, network, etc.) of a collection
# of processes.
#
# === Parameters
#
# [*cgconfig_name*]
#   (required) Full path for CGroups configuration file
# [*cgrules_path*]
#   (required) Full path fot CGroups Rules Engine Daemon configuration file
# [*cgroups_set*]
#   (required) Hiera hash with cgroups settings
# [*packages*]
#   (required) Names of packages for CGroups
#

class cgroups(
  $cgconfig_name = $cgroups::params::cgconfig_path,
  $cgrules_name  = $cgroups::params::cgrules_path,
  $cgroups_set   = $cgroups::params::cgroups_set,
  $packages      = $cgroups::params::packages,
)
  inherits cgroups::params
{

  ensure_packages($packages)

  File {
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
  }

  file { 'cgconfig.conf':
      name    => $cgconfig_name,
      content => template('cgroups/cgconfig.conf.erb'),
  }

  file { 'cgrules.conf':
      name    => $cgrules_name,
      content => template('cgroups/cgrules.conf.erb'),
   }

   class { '::cgroups::service': }

   Package<||> ->
   File<||> ->
   Service['cgroup-lite'] ->
   Service['cgconfigparser'] ->
   Cgclassify<||> ->
   Service['cgrulesengd']
}
