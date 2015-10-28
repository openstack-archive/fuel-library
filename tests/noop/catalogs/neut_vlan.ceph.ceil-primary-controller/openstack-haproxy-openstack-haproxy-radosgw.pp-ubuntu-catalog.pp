class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Haproxy_restart':
  name => 'Openstack::Ha::Haproxy_restart',
}

class { 'Openstack::Ha::Radosgw':
  internal_virtual_ip => '192.168.0.7',
  ipaddresses         => '172.16.0.2',
  name                => 'Openstack::Ha::Radosgw',
  public_ssl          => 'true',
  public_virtual_ip   => '172.16.0.3',
  server_names        => 'node-125',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

concat::fragment { 'radosgw_balancermember_radosgw':
  ensure  => 'present',
  content => '  server node-125 172.16.0.2:6780  check
',
  name    => 'radosgw_balancermember_radosgw',
  order   => '01-radosgw',
  target  => '/etc/haproxy/conf.d/130-radosgw.cfg',
}

concat::fragment { 'radosgw_listen_block':
  content => '
listen radosgw
  bind 172.16.0.3:8080 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.7:8080 
  option  httplog
  option  httpchk GET /
',
  name    => 'radosgw_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/130-radosgw.cfg',
}

concat { '/etc/haproxy/conf.d/130-radosgw.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/130-radosgw.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/130-radosgw.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/130-radosgw.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_130-radosgw.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_130-radosgw.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/130-radosgw.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_130-radosgw.cfg]', 'File[/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_130-radosgw.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_130-radosgw.cfg" -t',
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

file { '/etc/haproxy/conf.d/130-radosgw.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/130-radosgw.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/130-radosgw.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments/00_radosgw_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_radosgw_listen_block',
  backup  => 'puppet',
  content => '
listen radosgw
  bind 172.16.0.3:8080 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.7:8080 
  option  httplog
  option  httpchk GET /
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/130-radosgw.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments/00_radosgw_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments/01-radosgw_radosgw_balancermember_radosgw':
  ensure  => 'file',
  alias   => 'concat_fragment_radosgw_balancermember_radosgw',
  backup  => 'puppet',
  content => '  server node-125 172.16.0.2:6780  check
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/130-radosgw.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments/01-radosgw_radosgw_balancermember_radosgw',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/130-radosgw.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_130-radosgw.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_130-radosgw.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_130-radosgw.cfg',
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

haproxy::balancermember::collect_exported { 'radosgw':
  name => 'radosgw',
}

haproxy::balancermember { 'radosgw':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => '172.16.0.2',
  listening_service => 'radosgw',
  name              => 'radosgw',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check',
  order             => '130',
  ports             => '6780',
  server_names      => 'node-125',
  use_include       => 'true',
}

haproxy::listen { 'radosgw':
  bind             => {'172.16.0.3:8080' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '192.168.0.7:8080' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'radosgw',
  notify           => 'Exec[haproxy-restart]',
  options          => {'option' => ['httplog', 'httpchk GET /']},
  order            => '130',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'radosgw':
  balancermember_options => 'check',
  balancermember_port    => '6780',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'option' => ['httplog', 'httpchk GET /']},
  internal               => 'true',
  internal_virtual_ip    => '192.168.0.7',
  ipaddresses            => '172.16.0.2',
  listen_port            => '8080',
  name                   => 'radosgw',
  order                  => '130',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '172.16.0.3',
  server_names           => 'node-125',
}

stage { 'main':
  name => 'main',
}

