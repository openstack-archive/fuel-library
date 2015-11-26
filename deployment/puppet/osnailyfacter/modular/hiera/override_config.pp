notice('MODULAR: override_config.pp')

$data_dir            = '/etc/hiera'
$override_dir        = "${data_dir}/override"
$override_config_dir = "${override_dir}/config"

File {
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  ensure => 'directory',
}

file { [$override_dir, $override_config_dir]: }
