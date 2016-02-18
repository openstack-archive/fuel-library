class cgroups(
  $cgconfig_path = $cgroups::params::cgconfig_path,
  $cgrules_path  = $cgroups::params::cgrules_path,
  $cgroups_set   = $cgroups::params::cgroups_set,
  $packages      = $cgroups::params::packages,
#  $srv           = join(keys($cgroups_set), ' '),
)
  inherits cgroups::params
{
  include stdlib

  ensure_packages($packages)
#  package {$packages:
#    ensure => present,
#  }

  file { 'cgconfig.conf':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      path    => $cgconfig_path,
      content => template('cgroups/cgconfig.conf.erb'),
#      notify  => Class['cgroup-lite'],
  }

  file { 'cgrules.conf':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      path    => $cgrules_path,
      content => template('cgroups/cgrules.conf.erb'),
#      notify  => File['upstart_daemon'],
   }

   file { 'upstart_daemon':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      path    => '/etc/init/cgrulesengd.conf',
      source  => 'puppet:///modules/cgroups/cgrulesengd.conf',
#      notify  => ,
    }

    file { 'upstart_parser':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      path    => '/etc/init/cgconfigparser.conf',
      source  => 'puppet:///modules/cgroups/cgconfigparser.conf',
#      require => Package['cgroup-bin'];
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
