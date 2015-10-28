class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Haproxy_restart':
  name => 'Openstack::Ha::Haproxy_restart',
}

class { 'Openstack::Ha::Horizon':
  internal_virtual_ip => '192.168.0.7',
  ipaddresses         => '192.168.0.3',
  name                => 'Openstack::Ha::Horizon',
  public_virtual_ip   => '172.16.0.3',
  server_names        => 'node-125',
  use_ssl             => 'true',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

concat::fragment { 'horizon-ssl_balancermember_horizon-ssl':
  ensure  => 'present',
  content => '  server node-125 192.168.0.3:80  weight 1 check
',
  name    => 'horizon-ssl_balancermember_horizon-ssl',
  order   => '01-horizon-ssl',
  target  => '/etc/haproxy/conf.d/017-horizon-ssl.cfg',
}

concat::fragment { 'horizon-ssl_listen_block':
  content => '
listen horizon-ssl
  bind 172.16.0.3:443 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  balance  source
  mode  http
  option  forwardfor
  option  httpchk
  option  httpclose
  option  httplog
  reqadd  X-Forwarded-Proto:\ https
  stick  on src
  stick-table  type ip size 200k expire 30m
  timeout  client 3h
  timeout  server 3h
',
  name    => 'horizon-ssl_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/017-horizon-ssl.cfg',
}

concat::fragment { 'horizon_listen_block':
  content => '
listen horizon
  bind 172.16.0.3:80 
  redirect  scheme https if !{ ssl_fc }
',
  name    => 'horizon_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/015-horizon.cfg',
}

concat { '/etc/haproxy/conf.d/015-horizon.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/015-horizon.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/015-horizon.cfg',
  replace        => 'true',
  warn           => 'false',
}

concat { '/etc/haproxy/conf.d/017-horizon-ssl.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/017-horizon-ssl.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/017-horizon-ssl.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/015-horizon.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_015-horizon.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_015-horizon.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_015-horizon.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/015-horizon.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_015-horizon.cfg]', 'File[/tmp//_etc_haproxy_conf.d_015-horizon.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_015-horizon.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_015-horizon.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_015-horizon.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_015-horizon.cfg" -t',
}

exec { 'concat_/etc/haproxy/conf.d/017-horizon-ssl.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/017-horizon-ssl.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg]', 'File[/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg" -t',
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

file { '/etc/haproxy/conf.d/015-horizon.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/015-horizon.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/015-horizon.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_015-horizon.cfg/fragments.concat.out',
}

file { '/etc/haproxy/conf.d/017-horizon-ssl.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/017-horizon-ssl.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/017-horizon-ssl.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_015-horizon.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_015-horizon.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_015-horizon.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_015-horizon.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_015-horizon.cfg/fragments/00_horizon_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_listen_block',
  backup  => 'puppet',
  content => '
listen horizon
  bind 172.16.0.3:80 
  redirect  scheme https if !{ ssl_fc }
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/015-horizon.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_015-horizon.cfg/fragments/00_horizon_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_015-horizon.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/015-horizon.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_015-horizon.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_015-horizon.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_015-horizon.cfg',
}

file { '/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments/00_horizon-ssl_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon-ssl_listen_block',
  backup  => 'puppet',
  content => '
listen horizon-ssl
  bind 172.16.0.3:443 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  balance  source
  mode  http
  option  forwardfor
  option  httpchk
  option  httpclose
  option  httplog
  reqadd  X-Forwarded-Proto:\ https
  stick  on src
  stick-table  type ip size 200k expire 30m
  timeout  client 3h
  timeout  server 3h
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/017-horizon-ssl.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments/00_horizon-ssl_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments/01-horizon-ssl_horizon-ssl_balancermember_horizon-ssl':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon-ssl_balancermember_horizon-ssl',
  backup  => 'puppet',
  content => '  server node-125 192.168.0.3:80  weight 1 check
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/017-horizon-ssl.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments/01-horizon-ssl_horizon-ssl_balancermember_horizon-ssl',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/017-horizon-ssl.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_017-horizon-ssl.cfg',
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

haproxy::balancermember::collect_exported { 'horizon-ssl':
  name => 'horizon-ssl',
}

haproxy::balancermember::collect_exported { 'horizon':
  name => 'horizon',
}

haproxy::balancermember { 'horizon-ssl':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => '192.168.0.3',
  listening_service => 'horizon-ssl',
  name              => 'horizon-ssl',
  notify            => 'Exec[haproxy-restart]',
  options           => 'weight 1 check',
  order             => '017',
  ports             => '80',
  server_names      => 'node-125',
  use_include       => 'true',
}

haproxy::listen { 'horizon-ssl':
  bind             => {'172.16.0.3:443' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem']},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'horizon-ssl',
  notify           => 'Exec[haproxy-restart]',
  options          => {'balance' => 'source', 'mode' => 'http', 'option' => ['forwardfor', 'httpchk', 'httpclose', 'httplog'], 'reqadd' => 'X-Forwarded-Proto:\ https', 'stick' => 'on src', 'stick-table' => 'type ip size 200k expire 30m', 'timeout' => ['client 3h', 'server 3h']},
  order            => '017',
  use_include      => 'true',
}

haproxy::listen { 'horizon':
  bind             => {'172.16.0.3:80' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'horizon',
  notify           => 'Exec[haproxy-restart]',
  options          => {'redirect' => 'scheme https if !{ ssl_fc }'},
  order            => '015',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'horizon-ssl':
  balancermember_options => 'weight 1 check',
  balancermember_port    => '80',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'balance' => 'source', 'mode' => 'http', 'option' => ['forwardfor', 'httpchk', 'httpclose', 'httplog'], 'reqadd' => 'X-Forwarded-Proto:\ https', 'stick' => 'on src', 'stick-table' => 'type ip size 200k expire 30m', 'timeout' => ['client 3h', 'server 3h']},
  internal               => 'false',
  internal_virtual_ip    => '192.168.0.7',
  ipaddresses            => '192.168.0.3',
  listen_port            => '443',
  name                   => 'horizon-ssl',
  order                  => '017',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '172.16.0.3',
  server_names           => 'node-125',
}

openstack::ha::haproxy_service { 'horizon':
  balancermember_options => 'check',
  balancermember_port    => '80',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'redirect' => 'scheme https if !{ ssl_fc }'},
  internal               => 'false',
  internal_virtual_ip    => '192.168.0.7',
  listen_port            => '80',
  name                   => 'horizon',
  order                  => '015',
  public                 => 'true',
  public_ssl             => 'false',
  public_virtual_ip      => '172.16.0.3',
}

stage { 'main':
  name => 'main',
}

