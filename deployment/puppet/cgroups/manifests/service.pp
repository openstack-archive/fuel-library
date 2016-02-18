class cgroups::service (
  $cgroups_set = {},
  )

{
  notify {$cgroups_set: }

  service { 'cgroup-lite':
    ensure => running,
    enable => true,
  }

  service { 'cgconfigparser':
    ensure  => running,
    require => Service['cgroup-lite'],
  }

  service { 'cgrulesengd':
    ensure  => running,
  }

  generate_cgclassify($cgroups_set)
}
