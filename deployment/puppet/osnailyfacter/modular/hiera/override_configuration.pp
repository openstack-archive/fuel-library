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

#FIXME(mattymo): This is a plugin task for mitaka support
file { '/etc/facter/facts.d/os_package_type.txt':
  ensure  => 'file',
  content => 'os_package_type=ubuntu',
}
