class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Cinder':
  internal_virtual_ip => '192.168.0.7',
  ipaddresses         => '192.168.0.3',
  name                => 'Openstack::Ha::Cinder',
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

concat::fragment { 'cinder-api_balancermember_cinder-api':
  ensure  => 'present',
  content => '  server node-125 192.168.0.3:8776  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  name    => 'cinder-api_balancermember_cinder-api',
  order   => '01-cinder-api',
  target  => '/etc/haproxy/conf.d/070-cinder-api.cfg',
}

concat::fragment { 'cinder-api_listen_block':
  content => '
listen cinder-api
  bind 172.16.0.3:8776 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.7:8776 
  option  httpchk
  option  httplog
  option  httpclose
',
  name    => 'cinder-api_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/070-cinder-api.cfg',
}

concat { '/etc/haproxy/conf.d/070-cinder-api.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/070-cinder-api.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/070-cinder-api.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/070-cinder-api.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/070-cinder-api.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg]', 'File[/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg" -t',
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

file { '/etc/haproxy/conf.d/070-cinder-api.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/070-cinder-api.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/070-cinder-api.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments/00_cinder-api_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_cinder-api_listen_block',
  backup  => 'puppet',
  content => '
listen cinder-api
  bind 172.16.0.3:8776 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.7:8776 
  option  httpchk
  option  httplog
  option  httpclose
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/070-cinder-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments/00_cinder-api_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments/01-cinder-api_cinder-api_balancermember_cinder-api':
  ensure  => 'file',
  alias   => 'concat_fragment_cinder-api_balancermember_cinder-api',
  backup  => 'puppet',
  content => '  server node-125 192.168.0.3:8776  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/070-cinder-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments/01-cinder-api_cinder-api_balancermember_cinder-api',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/070-cinder-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_070-cinder-api.cfg',
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

haproxy::balancermember::collect_exported { 'cinder-api':
  name => 'cinder-api',
}

haproxy::balancermember { 'cinder-api':
  ensure            => 'present',
  define_backups    => 'true',
  define_cookies    => 'false',
  ipaddresses       => '192.168.0.3',
  listening_service => 'cinder-api',
  name              => 'cinder-api',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  order             => '070',
  ports             => '8776',
  server_names      => 'node-125',
  use_include       => 'true',
}

haproxy::listen { 'cinder-api':
  bind             => {'172.16.0.3:8776' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '192.168.0.7:8776' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'cinder-api',
  notify           => 'Exec[haproxy-restart]',
  options          => {'option' => ['httpchk', 'httplog', 'httpclose']},
  order            => '070',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'cinder-api':
  balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  balancermember_port    => '8776',
  before_start           => 'false',
  define_backups         => 'true',
  define_cookies         => 'false',
  haproxy_config_options => {'option' => ['httpchk', 'httplog', 'httpclose']},
  internal               => 'true',
  internal_virtual_ip    => '192.168.0.7',
  ipaddresses            => '192.168.0.3',
  listen_port            => '8776',
  name                   => 'cinder-api',
  order                  => '070',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '172.16.0.3',
  require_service        => 'cinder-api',
  server_names           => 'node-125',
}

stage { 'main':
  name => 'main',
}

