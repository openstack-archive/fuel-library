class cgroups::service (
  $cgroups_set = '{}',
)
{
  service { 'cgroup-lite':
    ensure => running,
    enable => true,
  }

  service { 'cgconfigparser':
    ensure  => running,
    require => Service['cgroup-lite'],
  }

  service { 'cgrulesengd':
    ensure => running,
  }
  
  $cgroups_set_active = pick($::cgroups::cgroups_set, $cgroups_set),
  $cgclass_res = map_cgclassify_opts($cgroups_set_active)
  unless empty($cgclass_res) {
    create_resources('cgclassify', $cgclass_res, { 'ensure' => present })
  }
}
