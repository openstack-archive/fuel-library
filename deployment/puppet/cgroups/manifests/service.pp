class cgroups::service (
  $cgroups_set = {},
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
    ensure  => running,
  }

  $cgclass_res = map_cgclassify_opts($cgroups_set)
  unless empty($cgclass_set) {
    create_resources('cgclassify', $cgclass_res, { 'ensure' => present })
  }
}
