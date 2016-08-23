Merge_yaml_settings {
  path             => '/tmp/test.yaml',
  original_data    => '/tmp/test.yaml',
  overwrite_arrays => true,
}

merge_yaml_settings { 'init' :
  original_data => { 'a' => '1' },
  override_data => { 'b' => '2' },
}

->

merge_yaml_settings { '1' :
  override_data => { 'c' => '3' },
}

->

merge_yaml_settings { '2' :
  override_data => { 'd' => ['1','2'] },
}

->

merge_yaml_settings { '3' :
  override_data => { 'd' => ['3','4'] },
}

->

merge_yaml_settings { '4' :
  override_data => { 'd' => ['3','4'] },
}
