class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Haproxy_restart':
  name => 'Openstack::Ha::Haproxy_restart',
}

class { 'Openstack::Ha::Swift':
  internal_virtual_ip => '192.168.0.5',
  ipaddresses         => '192.168.0.4',
  name                => 'Openstack::Ha::Swift',
  public_ssl          => 'true',
  public_virtual_ip   => '172.16.0.6',
  server_names        => 'node-137',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

concat::fragment { 'swift_balancermember_swift':
  ensure  => 'present',
  content => '  server node-137 192.168.0.4:8080  check port 49001 inter 15s fastinter 2s downinter 8s rise 3 fall 3
',
  name    => 'swift_balancermember_swift',
  order   => '01-swift',
  target  => '/etc/haproxy/conf.d/120-swift.cfg',
}

concat::fragment { 'swift_listen_block':
  content => '
listen swift
  bind 172.16.0.6:8080 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.5:8080 
  option  httpchk
  option  httplog
  option  httpclose
',
  name    => 'swift_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/120-swift.cfg',
}

concat { '/etc/haproxy/conf.d/120-swift.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/120-swift.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/120-swift.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/120-swift.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_120-swift.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_120-swift.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/120-swift.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_120-swift.cfg]', 'File[/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_120-swift.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_120-swift.cfg" -t',
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

file { '/etc/haproxy/conf.d/120-swift.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/120-swift.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/120-swift.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments/00_swift_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_listen_block',
  backup  => 'puppet',
  content => '
listen swift
  bind 172.16.0.6:8080 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.5:8080 
  option  httpchk
  option  httplog
  option  httpclose
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/120-swift.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments/00_swift_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments/01-swift_swift_balancermember_swift':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_balancermember_swift',
  backup  => 'puppet',
  content => '  server node-137 192.168.0.4:8080  check port 49001 inter 15s fastinter 2s downinter 8s rise 3 fall 3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/120-swift.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments/01-swift_swift_balancermember_swift',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/120-swift.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_120-swift.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_120-swift.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_120-swift.cfg',
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

haproxy::balancermember::collect_exported { 'swift':
  name => 'swift',
}

haproxy::balancermember { 'swift':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => '192.168.0.4',
  listening_service => 'swift',
  name              => 'swift',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check port 49001 inter 15s fastinter 2s downinter 8s rise 3 fall 3',
  order             => '120',
  ports             => '8080',
  server_names      => 'node-137',
  use_include       => 'true',
}

haproxy::listen { 'swift':
  bind             => {'172.16.0.6:8080' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '192.168.0.5:8080' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'swift',
  notify           => 'Exec[haproxy-restart]',
  options          => {'option' => ['httpchk', 'httplog', 'httpclose']},
  order            => '120',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'swift':
  balancermember_options => 'check port 49001 inter 15s fastinter 2s downinter 8s rise 3 fall 3',
  balancermember_port    => '8080',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'option' => ['httpchk', 'httplog', 'httpclose']},
  internal               => 'true',
  internal_virtual_ip    => '192.168.0.5',
  ipaddresses            => '192.168.0.4',
  listen_port            => '8080',
  name                   => 'swift',
  order                  => '120',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '172.16.0.6',
  server_names           => 'node-137',
}

stage { 'main':
  name => 'main',
}

