notice('MODULAR: hiera.pp')

$deep_merge_package_name = $::osfamily ? {
  /RedHat/ => 'rubygem-deep_merge',
  /Debian/ => 'ruby-deep-merge',
}

$data_dir            = '/etc/hiera'
$data                = [
  'override/node/%{::fqdn}',
  'override/class/%{calling_class}',
  'override/module/%{calling_module}',
  'override/plugins',
  'override/common',
  'class/%{calling_class}',
  'module/%{calling_module}',
  'nodes',
  'globals',
  'astute'
]
$astute_data_file    = '/etc/astute.yaml'
$hiera_main_config   = '/etc/hiera.yaml'
$hiera_puppet_config = '/etc/puppet/hiera.yaml'
$hiera_data_file     = "${data_dir}/astute.yaml"

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
:merge_behavior: deeper
:logger: noop
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

# needed to support the 'deeper' merge_behavior setting for hiera
package { 'rubygem-deep_merge':
  ensure => present,
  name   => $deep_merge_package_name,
}
