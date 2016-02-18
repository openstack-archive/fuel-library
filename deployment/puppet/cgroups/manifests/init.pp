# CGroups is a Linux kernel feature that limits, accounts for, and isolates
# the resource usage (CPU, memory, disk I/O, network, etc.) of a collection 
# of processes.
#
# $cgconfig_path - path for CGroups configuration file
# $cgrules_path  - path for CGroups Rules Engine Daemon configuration file
# $cgroups_set   - hiera hash with cgroups settings
# $packages      - names of packages for CGroups

class cgroups(
  $cgconfig_path = $cgroups::params::cgconfig_path,
  $cgrules_path  = $cgroups::params::cgrules_path,
  $cgroups_set   = $cgroups::params::cgroups_set,
  $packages      = $cgroups::params::packages,
)
  inherits cgroups::params
{
  include stdlib

  ensure_packages($packages)

  file { 'cgconfig.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      path    => $cgconfig_path,
      content => template('cgroups/cgconfig.conf.erb'),
  }

  file { 'cgrules.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      path    => $cgrules_path,
      content => template('cgroups/cgrules.conf.erb'),
   }

   file { 'upstart_daemon':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      path    => '/etc/init/cgrulesengd.conf',
      source  => 'puppet:///modules/cgroups/cgrulesengd.conf',
    }

    file { 'upstart_parser':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      path    => '/etc/init/cgconfigparser.conf',
      source  => 'puppet:///modules/cgroups/cgconfigparser.conf',
   }

   class { '::cgroups::service': }

   Package['cgroup-bin'] ->
   Package['libcgroup1'] ->
   File['cgconfig.conf'] ->
   File['cgrules.conf'] ->
   File['upstart_daemon'] ->
   File['upstart_parser'] ->
   Service['cgroup-lite'] ->
   Service['cgconfigparser'] ->
   Cgclassify<||> ->
   Service['cgrulesengd']
}
