class cgroups (
  $cgconfig_path = $::cgroups::params::cgconfig_path
  $cgrules_path  = $::cgroups::params::cgrules_path
  $cgroups_set   = $::cgroups::params::cgroups_set
  $packages      = $::cgroups::params::packages
  $srv           = $::cgroups::params::srv
){

  package {$packages:
    ensure => present,
  }

  file {
    "cgconfig.conf":
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      path    => $cgconfig_path,
      content => template('cgroups/cgconfig.conf.erb'),
      require => Package['cgroup-bin'],
      notify  => Service['cgroup-lite'];
    "cgrules.conf":
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      path    => $cgrules_path,
      content => template('cgroups/cgrules.conf.erb'),
      require => Package['libcgroup1'],
      notify  => File['upstart_daemon'];
     "upstart_daemon":
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      path    => '/etc/init/cgrulesengd.conf',
      content => template('cgroups/cgrulesengd.conf.erb'),
      require => Package['libcgroup1'],
      notify  => Exec['cgclassify'];
     "upstart_parser":
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      path    => '/etc/init/cgconfigparser.conf',
      content => template('cgroups/cgconfigparser.conf.erb'),
      require => Package['cgroup-bin'];
   }

   class { '::cgroups::service': }

   exec { 'cgclassify':
      command => 'cgclassify `pidof -x ${srv}`',
      path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      require => Package['cgroups-bin'],
      notify  => Service['cgrulesengd'];
   }
}
