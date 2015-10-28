class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Haproxy_restart':
  name => 'Openstack::Ha::Haproxy_restart',
}

class { 'Openstack::Ha::Sahara':
  internal_virtual_ip => '192.168.0.2',
  ipaddresses         => ['192.168.0.2', '192.168.0.3', '192.168.0.4'],
  name                => 'Openstack::Ha::Sahara',
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

concat::fragment { 'sahara_balancermember_sahara':
  ensure  => 'present',
  content => '  server node-128 192.168.0.2:8386  check
  server node-129 192.168.0.3:8386  check
  server node-131 192.168.0.4:8386  check
',
  name    => 'sahara_balancermember_sahara',
  order   => '01-sahara',
  target  => '/etc/haproxy/conf.d/150-sahara.cfg',
}

concat::fragment { 'sahara_listen_block':
  content => '
listen sahara
  bind 10.109.1.2:8386 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.2:8386 
  balance  roundrobin
  option  httplog
',
  name    => 'sahara_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/150-sahara.cfg',
}

concat { '/etc/haproxy/conf.d/150-sahara.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/150-sahara.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/150-sahara.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/150-sahara.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_150-sahara.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_150-sahara.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/150-sahara.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_150-sahara.cfg]', 'File[/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_150-sahara.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_150-sahara.cfg" -t',
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

file { '/etc/haproxy/conf.d/150-sahara.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/150-sahara.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/150-sahara.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments/00_sahara_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_sahara_listen_block',
  backup  => 'puppet',
  content => '
listen sahara
  bind 10.109.1.2:8386 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.2:8386 
  balance  roundrobin
  option  httplog
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/150-sahara.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments/00_sahara_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments/01-sahara_sahara_balancermember_sahara':
  ensure  => 'file',
  alias   => 'concat_fragment_sahara_balancermember_sahara',
  backup  => 'puppet',
  content => '  server node-128 192.168.0.2:8386  check
  server node-129 192.168.0.3:8386  check
  server node-131 192.168.0.4:8386  check
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/150-sahara.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments/01-sahara_sahara_balancermember_sahara',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/150-sahara.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_150-sahara.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_150-sahara.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_150-sahara.cfg',
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

haproxy::balancermember::collect_exported { 'sahara':
  name => 'sahara',
}

haproxy::balancermember { 'sahara':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => ['192.168.0.2', '192.168.0.3', '192.168.0.4'],
  listening_service => 'sahara',
  name              => 'sahara',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check',
  order             => '150',
  ports             => '8386',
  server_names      => ['node-128', 'node-129', 'node-131'],
  use_include       => 'true',
}

haproxy::listen { 'sahara':
  bind             => {'10.109.1.2:8386' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '192.168.0.2:8386' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'sahara',
  notify           => 'Exec[haproxy-restart]',
  options          => {'balance' => 'roundrobin', 'option' => ['httplog']},
  order            => '150',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'sahara':
  balancermember_options => 'check',
  balancermember_port    => '8386',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'balance' => 'roundrobin', 'option' => ['httplog']},
  internal               => 'true',
  internal_virtual_ip    => '192.168.0.2',
  ipaddresses            => ['192.168.0.2', '192.168.0.3', '192.168.0.4'],
  listen_port            => '8386',
  name                   => 'sahara',
  order                  => '150',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '10.109.1.2',
  require_service        => 'sahara-api',
  server_names           => ['node-128', 'node-129', 'node-131'],
}

stage { 'main':
  name => 'main',
}

