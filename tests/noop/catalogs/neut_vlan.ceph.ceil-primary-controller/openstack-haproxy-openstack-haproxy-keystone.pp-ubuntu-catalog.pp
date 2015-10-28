class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Haproxy_restart':
  name => 'Openstack::Ha::Haproxy_restart',
}

class { 'Openstack::Ha::Keystone':
  internal_virtual_ip => '192.168.0.7',
  ipaddresses         => '192.168.0.3',
  name                => 'Openstack::Ha::Keystone',
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

concat::fragment { 'keystone-1_balancermember_keystone-1':
  ensure  => 'present',
  content => '  server node-125 192.168.0.3:5000  check inter 10s fastinter 2s downinter 2s rise 30 fall 3
',
  name    => 'keystone-1_balancermember_keystone-1',
  order   => '01-keystone-1',
  target  => '/etc/haproxy/conf.d/020-keystone-1.cfg',
}

concat::fragment { 'keystone-1_listen_block':
  content => '
listen keystone-1
  bind 172.16.0.3:5000 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.7:5000 
  option  httpchk
  option  httplog
  option  httpclose
',
  name    => 'keystone-1_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/020-keystone-1.cfg',
}

concat::fragment { 'keystone-2_balancermember_keystone-2':
  ensure  => 'present',
  content => '  server node-125 192.168.0.3:35357  check inter 10s fastinter 2s downinter 2s rise 30 fall 3
',
  name    => 'keystone-2_balancermember_keystone-2',
  order   => '01-keystone-2',
  target  => '/etc/haproxy/conf.d/030-keystone-2.cfg',
}

concat::fragment { 'keystone-2_listen_block':
  content => '
listen keystone-2
  bind 192.168.0.7:35357 
  option  httpchk
  option  httplog
  option  httpclose
',
  name    => 'keystone-2_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/030-keystone-2.cfg',
}

concat { '/etc/haproxy/conf.d/020-keystone-1.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/020-keystone-1.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/020-keystone-1.cfg',
  replace        => 'true',
  warn           => 'false',
}

concat { '/etc/haproxy/conf.d/030-keystone-2.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/030-keystone-2.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/030-keystone-2.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/020-keystone-1.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/020-keystone-1.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg]', 'File[/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg" -t',
}

exec { 'concat_/etc/haproxy/conf.d/030-keystone-2.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/030-keystone-2.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg]', 'File[/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg" -t',
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

file { '/etc/haproxy/conf.d/020-keystone-1.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/020-keystone-1.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/020-keystone-1.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments.concat.out',
}

file { '/etc/haproxy/conf.d/030-keystone-2.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/030-keystone-2.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/030-keystone-2.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments/00_keystone-1_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone-1_listen_block',
  backup  => 'puppet',
  content => '
listen keystone-1
  bind 172.16.0.3:5000 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.7:5000 
  option  httpchk
  option  httplog
  option  httpclose
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/020-keystone-1.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments/00_keystone-1_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments/01-keystone-1_keystone-1_balancermember_keystone-1':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone-1_balancermember_keystone-1',
  backup  => 'puppet',
  content => '  server node-125 192.168.0.3:5000  check inter 10s fastinter 2s downinter 2s rise 30 fall 3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/020-keystone-1.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments/01-keystone-1_keystone-1_balancermember_keystone-1',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/020-keystone-1.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_020-keystone-1.cfg',
}

file { '/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments/00_keystone-2_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone-2_listen_block',
  backup  => 'puppet',
  content => '
listen keystone-2
  bind 192.168.0.7:35357 
  option  httpchk
  option  httplog
  option  httpclose
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/030-keystone-2.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments/00_keystone-2_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments/01-keystone-2_keystone-2_balancermember_keystone-2':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone-2_balancermember_keystone-2',
  backup  => 'puppet',
  content => '  server node-125 192.168.0.3:35357  check inter 10s fastinter 2s downinter 2s rise 30 fall 3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/030-keystone-2.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments/01-keystone-2_keystone-2_balancermember_keystone-2',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/030-keystone-2.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_030-keystone-2.cfg',
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

haproxy::balancermember::collect_exported { 'keystone-1':
  name => 'keystone-1',
}

haproxy::balancermember::collect_exported { 'keystone-2':
  name => 'keystone-2',
}

haproxy::balancermember { 'keystone-1':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => '192.168.0.3',
  listening_service => 'keystone-1',
  name              => 'keystone-1',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check inter 10s fastinter 2s downinter 2s rise 30 fall 3',
  order             => '020',
  ports             => '5000',
  server_names      => 'node-125',
  use_include       => 'true',
}

haproxy::balancermember { 'keystone-2':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => '192.168.0.3',
  listening_service => 'keystone-2',
  name              => 'keystone-2',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check inter 10s fastinter 2s downinter 2s rise 30 fall 3',
  order             => '030',
  ports             => '35357',
  server_names      => 'node-125',
  use_include       => 'true',
}

haproxy::listen { 'keystone-1':
  bind             => {'172.16.0.3:5000' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '192.168.0.7:5000' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'keystone-1',
  notify           => 'Exec[haproxy-restart]',
  options          => {'option' => ['httpchk', 'httplog', 'httpclose']},
  order            => '020',
  use_include      => 'true',
}

haproxy::listen { 'keystone-2':
  bind             => {'192.168.0.7:35357' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'keystone-2',
  notify           => 'Exec[haproxy-restart]',
  options          => {'option' => ['httpchk', 'httplog', 'httpclose']},
  order            => '030',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'keystone-1':
  balancermember_options => 'check inter 10s fastinter 2s downinter 2s rise 30 fall 3',
  balancermember_port    => '5000',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'option' => ['httpchk', 'httplog', 'httpclose']},
  internal               => 'true',
  internal_virtual_ip    => '192.168.0.7',
  ipaddresses            => '192.168.0.3',
  listen_port            => '5000',
  name                   => 'keystone-1',
  order                  => '020',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '172.16.0.3',
  server_names           => 'node-125',
}

openstack::ha::haproxy_service { 'keystone-2':
  balancermember_options => 'check inter 10s fastinter 2s downinter 2s rise 30 fall 3',
  balancermember_port    => '35357',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'option' => ['httpchk', 'httplog', 'httpclose']},
  internal               => 'true',
  internal_virtual_ip    => '192.168.0.7',
  ipaddresses            => '192.168.0.3',
  listen_port            => '35357',
  name                   => 'keystone-2',
  order                  => '030',
  public                 => 'false',
  public_ssl             => 'false',
  public_virtual_ip      => '172.16.0.3',
  server_names           => 'node-125',
}

stage { 'main':
  name => 'main',
}

