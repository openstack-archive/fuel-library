$data_dir            = '/etc/hiera'
$data                = ['globals','astute']
$astute_data_file    = '/etc/astute.yaml'
$hiera_main_config   = '/etc/hiera.yaml'
$hiera_puppet_config = '/etc/puppet/hiera.yaml'
$hiera_data_file     = "${data_dir}/${data_name}.yaml"

File {
  owner => 'root',
  group => 'root',
  mode  => '0644',
}

$hiera_config_content = inline_template('
---
:backends:
  - yaml

:hierarchy:
<% @data.each do |name| -%>
  - <%= name %>
<% end -%>

:yaml:
  :datadir: <%= @data_dir %>
')

file { 'hiera_data_dir' :
  ensure => 'directory',
  path   => $data_dir,
}

file { 'hiera_config' :
  ensure  => 'present',
  path    => $hiera_main_config,
  content => $hiera_config_content,
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
