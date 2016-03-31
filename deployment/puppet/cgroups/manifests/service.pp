class cgroups::service (
  $cgroups_settings = {},
)
{
  service { 'cgroup-lite':
    ensure => running,
    enable => true,
  }

  service { 'cgconfigparser':
    ensure    => running,
    hasstatus => false,
    status    => '/bin/true',
    restart   => 'service cgconfigparser restart',
    require   => Service['cgroup-lite'],
  }

  service { 'cgrulesengd':
    ensure => running,
  }

  $cgclass_res = map_cgclassify_opts($cgroups_settings)
  unless empty($cgclass_res) {
    create_resources('cgclassify', $cgclass_res, { 'ensure' => present })
  }
}
