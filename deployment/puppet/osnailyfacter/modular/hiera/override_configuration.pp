notice('MODULAR: override_configuration.pp')

$hiera_data_dir            = '/etc/hiera'
$hiera_override_dir        = "${hiera_data_dir}/override"
$hiera_override_config_dir = "${hiera_override_dir}/configuration"

File {
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  ensure => 'directory',
}

file { [$hiera_override_dir, $hiera_override_config_dir]: }
