class cgroups::service (
  $cgroups_settings = {},
) {

  service { 'cgconfig':
    ensure   => running,
    enable   => true,
    provider => 'init',
  }

  $cgclass_res = map_cgclassify_opts($cgroups_settings)
  unless empty($cgclass_res) {
    create_resources('cgclassify', $cgclass_res, { 'ensure' => present })
  }

}
