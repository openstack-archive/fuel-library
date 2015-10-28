class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Ceilometer':
  internal_virtual_ip => '192.168.0.7',
  ipaddresses         => '192.168.0.3',
  name                => 'Openstack::Ha::Ceilometer',
  public_ssl          => 'true',
  public_virtual_ip   => '172.16.0.3',
  server_names        => 'node-125',
}

class { 'Openstack::Ha::Haproxy_restart':
  name => 'Openstack::Ha::Haproxy_restart',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

concat::fragment { 'ceilometer_balancermember_ceilometer':
  ensure  => 'present',
  content => '  server node-125 192.168.0.3:8777  check
',
  name    => 'ceilometer_balancermember_ceilometer',
  order   => '01-ceilometer',
  target  => '/etc/haproxy/conf.d/140-ceilometer.cfg',
}

concat::fragment { 'ceilometer_listen_block':
  content => '
listen ceilometer
  bind 172.16.0.3:8777 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.7:8777 
  balance  roundrobin
  option  httplog
',
  name    => 'ceilometer_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/140-ceilometer.cfg',
}

concat { '/etc/haproxy/conf.d/140-ceilometer.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/140-ceilometer.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/140-ceilometer.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/140-ceilometer.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/140-ceilometer.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg]', 'File[/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg" -t',
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

file { '/etc/haproxy/conf.d/140-ceilometer.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/140-ceilometer.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/140-ceilometer.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments/00_ceilometer_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_ceilometer_listen_block',
  backup  => 'puppet',
  content => '
listen ceilometer
  bind 172.16.0.3:8777 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.7:8777 
  balance  roundrobin
  option  httplog
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/140-ceilometer.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments/00_ceilometer_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments/01-ceilometer_ceilometer_balancermember_ceilometer':
  ensure  => 'file',
  alias   => 'concat_fragment_ceilometer_balancermember_ceilometer',
  backup  => 'puppet',
  content => '  server node-125 192.168.0.3:8777  check
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/140-ceilometer.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments/01-ceilometer_ceilometer_balancermember_ceilometer',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/140-ceilometer.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_140-ceilometer.cfg',
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

haproxy::balancermember::collect_exported { 'ceilometer':
  name => 'ceilometer',
}

haproxy::balancermember { 'ceilometer':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => '192.168.0.3',
  listening_service => 'ceilometer',
  name              => 'ceilometer',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check',
  order             => '140',
  ports             => '8777',
  server_names      => 'node-125',
  use_include       => 'true',
}

haproxy::listen { 'ceilometer':
  bind             => {'172.16.0.3:8777' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '192.168.0.7:8777' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'ceilometer',
  notify           => 'Exec[haproxy-restart]',
  options          => {'balance' => 'roundrobin', 'option' => ['httplog']},
  order            => '140',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'ceilometer':
  balancermember_options => 'check',
  balancermember_port    => '8777',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'balance' => 'roundrobin', 'option' => ['httplog']},
  internal               => 'true',
  internal_virtual_ip    => '192.168.0.7',
  ipaddresses            => '192.168.0.3',
  listen_port            => '8777',
  name                   => 'ceilometer',
  order                  => '140',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '172.16.0.3',
  require_service        => 'ceilometer-api',
  server_names           => 'node-125',
}

stage { 'main':
  name => 'main',
}

