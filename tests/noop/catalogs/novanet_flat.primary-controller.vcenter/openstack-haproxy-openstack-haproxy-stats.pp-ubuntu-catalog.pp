class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Haproxy_restart':
  name => 'Openstack::Ha::Haproxy_restart',
}

class { 'Openstack::Ha::Stats':
  internal_virtual_ip => '10.108.2.2',
  name                => 'Openstack::Ha::Stats',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

concat::fragment { 'stats_listen_block':
  content => '
listen stats
  bind 10.108.2.2:10000 
  mode  http
  stats  enable
  stats  uri /
  stats  refresh 5s
  stats  show-node
  stats  show-legends
  stats  hide-version
',
  name    => 'stats_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/010-stats.cfg',
}

concat { '/etc/haproxy/conf.d/010-stats.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/010-stats.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/010-stats.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/010-stats.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_010-stats.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_010-stats.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_010-stats.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/010-stats.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_010-stats.cfg]', 'File[/tmp//_etc_haproxy_conf.d_010-stats.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_010-stats.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_010-stats.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_010-stats.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_010-stats.cfg" -t',
}

exec { 'haproxy-restart':
  command     => '/usr/lib/ocf/resource.d/fuel/ns_haproxy reload',
  environment => 'OCF_ROOT=/usr/lib/ocf',
  logoutput   => 'true',
  path        => '/usr/bin:/usr/sbin:/bin:/sbin',
  provider    => 'shell',
  refreshonly => 'true',
  returns     => ['0', ''],
  tries       => '10',
  try_sleep   => '10',
}

file { '/etc/haproxy/conf.d/010-stats.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/010-stats.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/010-stats.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_010-stats.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_010-stats.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_010-stats.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_010-stats.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_010-stats.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_010-stats.cfg/fragments/00_stats_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_stats_listen_block',
  backup  => 'puppet',
  content => '
listen stats
  bind 10.108.2.2:10000 
  mode  http
  stats  enable
  stats  uri /
  stats  refresh 5s
  stats  show-node
  stats  show-legends
  stats  hide-version
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/010-stats.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_010-stats.cfg/fragments/00_stats_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_010-stats.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/010-stats.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_010-stats.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_010-stats.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_010-stats.cfg',
}

file { '/tmp//bin/concatfragments.rb':
  ensure => 'file',
  backup => 'puppet',
  mode   => '0755',
  path   => '/tmp//bin/concatfragments.rb',
  source => 'puppet:///modules/concat/concatfragments.rb',
}

file { '/tmp//bin':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0755',
  path   => '/tmp//bin',
}

file { '/tmp/':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0755',
  path   => '/tmp',
}

haproxy::balancermember::collect_exported { 'stats':
  name => 'stats',
}

haproxy::listen { 'stats':
  bind             => {'10.108.2.2:10000' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'stats',
  notify           => 'Exec[haproxy-restart]',
  options          => {'mode' => 'http', 'stats' => ['enable', 'uri /', 'refresh 5s', 'show-node', 'show-legends', 'hide-version']},
  order            => '010',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'stats':
  balancermember_options => 'check',
  balancermember_port    => '10000',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'mode' => 'http', 'stats' => ['enable', 'uri /', 'refresh 5s', 'show-node', 'show-legends', 'hide-version']},
  internal               => 'true',
  internal_virtual_ip    => '10.108.2.2',
  listen_port            => '10000',
  name                   => 'stats',
  order                  => '010',
  public                 => 'false',
  public_ssl             => 'false',
}

stage { 'main':
  name => 'main',
}

