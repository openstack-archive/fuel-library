class cgroups::service
  inherits cgroups::params
{
  notify {$cgroups_set: }

  service { 'cgroup-lite':
    ensure => running,
    enable => true,
    name   => 'cgroup-lite',
  }

  service { 'cgconfigparser':
    ensure  => running,
    name    => 'cgconfigparser',
    require => Service['cgroup-lite'],
  }

  service { 'cgrulesengd':
    ensure  => running,
    name    => 'cgrulesengd',
  }

  generate_cgclassify($cgroups_set)
}
