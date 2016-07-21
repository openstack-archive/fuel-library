class osnailyfacter::hiera::hiera {

  notice('MODULAR: hiera/hiera.pp')

  $data_dir            = '/etc/hiera'
  $override_dir        = 'plugins'
  $override_dir_path   = "${data_dir}/${override_dir}"
  $metadata_file       = '/etc/astute.yaml'

  $data = [
    'override/node/%{::fqdn}',
    'override/class/%{calling_class}',
    'override/module/%{calling_module}',
    'override/plugins',
    'override/common',
    'override/configuration/%{::fqdn}',
    'override/configuration/role',
    'override/configuration/cluster',
    'override/configuration/default_route',
    'class/%{calling_class}',
    'module/%{calling_module}',
    'deleted_nodes',
    'nodes',
    'globals%{disable_globals_yaml}',
    'astute',
  ]

  $astute_data_file    = '/etc/astute.yaml'
  $hiera_main_config   = '/etc/hiera.yaml'
  $hiera_puppet_config = '/etc/puppet/hiera.yaml'
  $hiera_data_file     = "${data_dir}/astute.yaml"

  File {
    owner => 'root',
    group => 'root',
    mode  => '0640',
  }

  hiera_config { $hiera_main_config :
    ensure             => 'present',
    data_dir           => $data_dir,
    hierarchy          => $data,
    override_dir       => $override_dir,
    metadata_yaml_file => $metadata_file,
    merge_behavior     => 'deeper',
  }

  file { 'hiera_data_dir' :
    ensure => 'directory',
    mode   => '0750',
    path   => $data_dir,
  }

  file { 'hiera_data_override_dir' :
    ensure => 'directory',
    mode   => '0750',
    path   => $override_dir_path,
  }

  file { 'hiera_config' :
    ensure => 'present',
    path   => $hiera_main_config,
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

}
