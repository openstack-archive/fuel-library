notice('MODULAR: override_config.pp')

$data_dir            = '/etc/hiera'
$override_dir        = "${data_dir}/override"
$override_config_dir = "${override_dir}/config"

File {
  owner => 'root',
  group => 'root',
  mode  => '0644',
}

file { 'hiera_override' :
  ensure => 'directory',
  path   => $override_dir,
}

file { 'hiera_override_config' :
  ensure => 'directory',
  path   => $override_config_dir,
}
