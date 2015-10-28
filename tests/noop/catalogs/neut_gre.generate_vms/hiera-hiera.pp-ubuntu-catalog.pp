class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

file { 'hiera_config':
  ensure  => 'present',
  content => '
---
:backends:
  - yaml

:hierarchy:
  - override/node/%{::fqdn}
  - override/class/%{calling_class}
  - override/module/%{calling_module}
  - override/plugins
  - override/common
  - class/%{calling_class}
  - module/%{calling_module}
  - nodes
  - globals
  - astute

:yaml:
  :datadir: /etc/hiera
:merge_behavior: deeper
:logger: noop
',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/hiera.yaml',
}

file { 'hiera_data_astute':
  ensure => 'symlink',
  group  => 'root',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/hiera/astute.yaml',
  target => '/etc/astute.yaml',
}

file { 'hiera_data_dir':
  ensure => 'directory',
  group  => 'root',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/hiera',
}

file { 'hiera_puppet_config':
  ensure => 'symlink',
  group  => 'root',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/puppet/hiera.yaml',
  target => '/etc/hiera.yaml',
}

package { 'rubygem-deep_merge':
  ensure => 'present',
  name   => 'ruby-deep-merge',
}

stage { 'main':
  name => 'main',
}

