class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Haproxy_restart':
  name => 'Openstack::Ha::Haproxy_restart',
}

class { 'Openstack::Ha::Mysqld':
  before_start          => 'false',
  internal_virtual_ip   => '192.168.0.5',
  ipaddresses           => '192.168.0.4',
  is_primary_controller => 'true',
  name                  => 'Openstack::Ha::Mysqld',
  public_virtual_ip     => '172.16.0.6',
  server_names          => 'node-137',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

concat::fragment { 'mysqld_balancermember_mysqld':
  ensure  => 'present',
  content => '  server node-137 192.168.0.4:3307  check port 49000 inter 20s fastinter 2s downinter 2s rise 3 fall 3
',
  name    => 'mysqld_balancermember_mysqld',
  order   => '01-mysqld',
  target  => '/etc/haproxy/conf.d/110-mysqld.cfg',
}

concat::fragment { 'mysqld_listen_block':
  content => '
listen mysqld
  bind 192.168.0.5:3306 
  balance  leastconn
  mode  tcp
  option  httpchk
  option  tcplog
  option  clitcpka
  option  srvtcpka
  timeout client  28801s
  timeout server  28801s
',
  name    => 'mysqld_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/110-mysqld.cfg',
}

concat { '/etc/haproxy/conf.d/110-mysqld.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/110-mysqld.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/110-mysqld.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/110-mysqld.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_110-mysqld.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_110-mysqld.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/110-mysqld.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_110-mysqld.cfg]', 'File[/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_110-mysqld.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_110-mysqld.cfg" -t',
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

file { '/etc/haproxy/conf.d/110-mysqld.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/110-mysqld.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/110-mysqld.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments/00_mysqld_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_mysqld_listen_block',
  backup  => 'puppet',
  content => '
listen mysqld
  bind 192.168.0.5:3306 
  balance  leastconn
  mode  tcp
  option  httpchk
  option  tcplog
  option  clitcpka
  option  srvtcpka
  timeout client  28801s
  timeout server  28801s
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/110-mysqld.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments/00_mysqld_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments/01-mysqld_mysqld_balancermember_mysqld':
  ensure  => 'file',
  alias   => 'concat_fragment_mysqld_balancermember_mysqld',
  backup  => 'puppet',
  content => '  server node-137 192.168.0.4:3307  check port 49000 inter 20s fastinter 2s downinter 2s rise 3 fall 3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/110-mysqld.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments/01-mysqld_mysqld_balancermember_mysqld',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/110-mysqld.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_110-mysqld.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_110-mysqld.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_110-mysqld.cfg',
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

haproxy::balancermember::collect_exported { 'mysqld':
  name => 'mysqld',
}

haproxy::balancermember { 'mysqld':
  ensure            => 'present',
  define_backups    => 'true',
  define_cookies    => 'false',
  ipaddresses       => '192.168.0.4',
  listening_service => 'mysqld',
  name              => 'mysqld',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check port 49000 inter 20s fastinter 2s downinter 2s rise 3 fall 3',
  order             => '110',
  ports             => '3307',
  server_names      => 'node-137',
  use_include       => 'true',
}

haproxy::listen { 'mysqld':
  bind             => {'192.168.0.5:3306' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'mysqld',
  notify           => 'Exec[haproxy-restart]',
  options          => {'balance' => 'leastconn', 'mode' => 'tcp', 'option' => ['httpchk', 'tcplog', 'clitcpka', 'srvtcpka'], 'timeout client' => '28801s', 'timeout server' => '28801s'},
  order            => '110',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'mysqld':
  balancermember_options => 'check port 49000 inter 20s fastinter 2s downinter 2s rise 3 fall 3',
  balancermember_port    => '3307',
  before_start           => 'false',
  define_backups         => 'true',
  define_cookies         => 'false',
  haproxy_config_options => {'balance' => 'leastconn', 'mode' => 'tcp', 'option' => ['httpchk', 'tcplog', 'clitcpka', 'srvtcpka'], 'timeout client' => '28801s', 'timeout server' => '28801s'},
  internal               => 'true',
  internal_virtual_ip    => '192.168.0.5',
  ipaddresses            => '192.168.0.4',
  listen_port            => '3306',
  name                   => 'mysqld',
  order                  => '110',
  public                 => 'false',
  public_ssl             => 'false',
  public_virtual_ip      => '172.16.0.6',
  server_names           => 'node-137',
}

stage { 'main':
  name => 'main',
}

