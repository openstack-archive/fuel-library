notice('MODULAR: override_configuration.pp')

$data_dir            = '/etc/hiera'
$override_dir        = "${data_dir}/override"
$override_config_dir = "${override_dir}/configuration"

File {
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  ensure => 'directory',
}

file { [$override_dir, $override_config_dir]: }
