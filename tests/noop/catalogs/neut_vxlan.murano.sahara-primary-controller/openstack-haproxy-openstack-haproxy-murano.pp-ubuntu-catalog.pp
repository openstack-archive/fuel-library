class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Haproxy_restart':
  name => 'Openstack::Ha::Haproxy_restart',
}

class { 'Openstack::Ha::Murano':
  internal_virtual_ip => '192.168.0.2',
  ipaddresses         => ['192.168.0.2', '192.168.0.3', '192.168.0.4'],
  name                => 'Openstack::Ha::Murano',
  public_ssl          => 'true',
  public_virtual_ip   => '10.109.1.2',
  server_names        => ['node-128', 'node-129', 'node-131'],
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

concat::fragment { 'murano-api_balancermember_murano-api':
  ensure  => 'present',
  content => '  server node-128 192.168.0.2:8082  check
  server node-129 192.168.0.3:8082  check
  server node-131 192.168.0.4:8082  check
',
  name    => 'murano-api_balancermember_murano-api',
  order   => '01-murano-api',
  target  => '/etc/haproxy/conf.d/180-murano-api.cfg',
}

concat::fragment { 'murano-api_listen_block':
  content => '
listen murano-api
  bind 10.109.1.2:8082 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.2:8082 
  balance  roundrobin
  option  httplog
',
  name    => 'murano-api_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/180-murano-api.cfg',
}

concat::fragment { 'murano_rabbitmq_balancermember_murano_rabbitmq':
  ensure  => 'present',
  content => '  server node-128 192.168.0.2:55572  check inter 5000 rise 2 fall 3
  server node-129 192.168.0.3:55572 backup check inter 5000 rise 2 fall 3
  server node-131 192.168.0.4:55572 backup check inter 5000 rise 2 fall 3
',
  name    => 'murano_rabbitmq_balancermember_murano_rabbitmq',
  order   => '01-murano_rabbitmq',
  target  => '/etc/haproxy/conf.d/190-murano_rabbitmq.cfg',
}

concat::fragment { 'murano_rabbitmq_listen_block':
  content => '
listen murano_rabbitmq
  bind 10.109.1.2:55572 
  balance  roundrobin
  mode  tcp
  option  tcpka
  timeout client  48h
  timeout server  48h
',
  name    => 'murano_rabbitmq_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/190-murano_rabbitmq.cfg',
}

concat { '/etc/haproxy/conf.d/180-murano-api.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/180-murano-api.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/180-murano-api.cfg',
  replace        => 'true',
  warn           => 'false',
}

concat { '/etc/haproxy/conf.d/190-murano_rabbitmq.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/190-murano_rabbitmq.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/190-murano_rabbitmq.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/180-murano-api.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_180-murano-api.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_180-murano-api.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/180-murano-api.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_180-murano-api.cfg]', 'File[/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_180-murano-api.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_180-murano-api.cfg" -t',
}

exec { 'concat_/etc/haproxy/conf.d/190-murano_rabbitmq.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/190-murano_rabbitmq.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg]', 'File[/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg" -t',
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

file { '/etc/haproxy/conf.d/180-murano-api.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/180-murano-api.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/180-murano-api.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments.concat.out',
}

file { '/etc/haproxy/conf.d/190-murano_rabbitmq.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/190-murano_rabbitmq.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/190-murano_rabbitmq.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments/00_murano-api_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_murano-api_listen_block',
  backup  => 'puppet',
  content => '
listen murano-api
  bind 10.109.1.2:8082 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.2:8082 
  balance  roundrobin
  option  httplog
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/180-murano-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments/00_murano-api_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments/01-murano-api_murano-api_balancermember_murano-api':
  ensure  => 'file',
  alias   => 'concat_fragment_murano-api_balancermember_murano-api',
  backup  => 'puppet',
  content => '  server node-128 192.168.0.2:8082  check
  server node-129 192.168.0.3:8082  check
  server node-131 192.168.0.4:8082  check
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/180-murano-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments/01-murano-api_murano-api_balancermember_murano-api',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/180-murano-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_180-murano-api.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_180-murano-api.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_180-murano-api.cfg',
}

file { '/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments/00_murano_rabbitmq_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_murano_rabbitmq_listen_block',
  backup  => 'puppet',
  content => '
listen murano_rabbitmq
  bind 10.109.1.2:55572 
  balance  roundrobin
  mode  tcp
  option  tcpka
  timeout client  48h
  timeout server  48h
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/190-murano_rabbitmq.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments/00_murano_rabbitmq_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments/01-murano_rabbitmq_murano_rabbitmq_balancermember_murano_rabbitmq':
  ensure  => 'file',
  alias   => 'concat_fragment_murano_rabbitmq_balancermember_murano_rabbitmq',
  backup  => 'puppet',
  content => '  server node-128 192.168.0.2:55572  check inter 5000 rise 2 fall 3
  server node-129 192.168.0.3:55572 backup check inter 5000 rise 2 fall 3
  server node-131 192.168.0.4:55572 backup check inter 5000 rise 2 fall 3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/190-murano_rabbitmq.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments/01-murano_rabbitmq_murano_rabbitmq_balancermember_murano_rabbitmq',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/190-murano_rabbitmq.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_190-murano_rabbitmq.cfg',
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

haproxy::balancermember::collect_exported { 'murano-api':
  name => 'murano-api',
}

haproxy::balancermember::collect_exported { 'murano_rabbitmq':
  name => 'murano_rabbitmq',
}

haproxy::balancermember { 'murano-api':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => ['192.168.0.2', '192.168.0.3', '192.168.0.4'],
  listening_service => 'murano-api',
  name              => 'murano-api',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check',
  order             => '180',
  ports             => '8082',
  server_names      => ['node-128', 'node-129', 'node-131'],
  use_include       => 'true',
}

haproxy::balancermember { 'murano_rabbitmq':
  ensure            => 'present',
  define_backups    => 'true',
  define_cookies    => 'false',
  ipaddresses       => ['192.168.0.2', '192.168.0.3', '192.168.0.4'],
  listening_service => 'murano_rabbitmq',
  name              => 'murano_rabbitmq',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check inter 5000 rise 2 fall 3',
  order             => '190',
  ports             => '55572',
  server_names      => ['node-128', 'node-129', 'node-131'],
  use_include       => 'true',
}

haproxy::listen { 'murano-api':
  bind             => {'10.109.1.2:8082' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '192.168.0.2:8082' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'murano-api',
  notify           => 'Exec[haproxy-restart]',
  options          => {'balance' => 'roundrobin', 'option' => ['httplog']},
  order            => '180',
  use_include      => 'true',
}

haproxy::listen { 'murano_rabbitmq':
  bind             => {'10.109.1.2:55572' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'murano_rabbitmq',
  notify           => 'Exec[haproxy-restart]',
  options          => {'balance' => 'roundrobin', 'mode' => 'tcp', 'option' => ['tcpka'], 'timeout client' => '48h', 'timeout server' => '48h'},
  order            => '190',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'murano-api':
  balancermember_options => 'check',
  balancermember_port    => '8082',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'balance' => 'roundrobin', 'option' => ['httplog']},
  internal               => 'true',
  internal_virtual_ip    => '192.168.0.2',
  ipaddresses            => ['192.168.0.2', '192.168.0.3', '192.168.0.4'],
  listen_port            => '8082',
  name                   => 'murano-api',
  order                  => '180',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '10.109.1.2',
  require_service        => 'murano_api',
  server_names           => ['node-128', 'node-129', 'node-131'],
}

openstack::ha::haproxy_service { 'murano_rabbitmq':
  balancermember_options => 'check inter 5000 rise 2 fall 3',
  balancermember_port    => '55572',
  before_start           => 'false',
  define_backups         => 'true',
  define_cookies         => 'false',
  haproxy_config_options => {'balance' => 'roundrobin', 'mode' => 'tcp', 'option' => ['tcpka'], 'timeout client' => '48h', 'timeout server' => '48h'},
  internal               => 'false',
  internal_virtual_ip    => '192.168.0.2',
  ipaddresses            => ['192.168.0.2', '192.168.0.3', '192.168.0.4'],
  listen_port            => '55572',
  name                   => 'murano_rabbitmq',
  order                  => '190',
  public                 => 'true',
  public_ssl             => 'false',
  public_virtual_ip      => '10.109.1.2',
  server_names           => ['node-128', 'node-129', 'node-131'],
}

stage { 'main':
  name => 'main',
}

