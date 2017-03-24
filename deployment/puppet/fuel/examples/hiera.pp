$data_dir            = '/etc/hiera'
$data                = [
  'override/common',
  'class/%{calling_class}',
  'module/%{calling_module}',
  'nodes',
  'networks',
  'astute',
  'common',
]
$astute_data_file    = '/etc/fuel/astute.yaml'
$hiera_main_config   = '/etc/hiera.yaml'
$hiera_puppet_config = '/etc/puppet/hiera.yaml'
$hiera_data_file     = "${data_dir}/astute.yaml"

File {
  owner => 'root',
  group => 'root',
}

hiera_config { 'master_hiera_yaml':
  ensure           => 'present',
  path             => $hiera_main_config,
  data_dir         => $data_dir,
  backends         => ['yaml'],
  hierarchy_bottom => $data,
  logger           => 'noop',
  merge_behavior   => 'deeper',
}

file { 'hiera_data_dir' :
  ensure => 'directory',
  path   => $data_dir,
  mode   => '0750',
}

file { 'hiera_data_astute' :
  ensure => 'symlink',
  path   => $hiera_data_file,
  target => $astute_data_file,
}

file { 'hiera_puppet_config' :
  ensure => 'symlink',
  path   => $hiera_puppet_config,
  target => $hiera_main_config,
}

Hiera_config['master_hiera_yaml'] ->
File['hiera_puppet_config']
