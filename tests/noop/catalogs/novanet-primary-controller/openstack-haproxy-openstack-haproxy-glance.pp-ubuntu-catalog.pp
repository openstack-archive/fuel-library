class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Glance':
  internal_virtual_ip => '192.168.0.5',
  ipaddresses         => '192.168.0.4',
  name                => 'Openstack::Ha::Glance',
  public_ssl          => 'true',
  public_virtual_ip   => '172.16.0.6',
  server_names        => 'node-137',
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

concat::fragment { 'glance-api_balancermember_glance-api':
  ensure  => 'present',
  content => '  server node-137 192.168.0.4:9292  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  name    => 'glance-api_balancermember_glance-api',
  order   => '01-glance-api',
  target  => '/etc/haproxy/conf.d/080-glance-api.cfg',
}

concat::fragment { 'glance-api_listen_block':
  content => '
listen glance-api
  bind 172.16.0.6:9292 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.5:9292 
  option  httpchk /versions
  option  httplog
  option  httpclose
  timeout server  11m
',
  name    => 'glance-api_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/080-glance-api.cfg',
}

concat::fragment { 'glance-registry_balancermember_glance-registry':
  ensure  => 'present',
  content => '  server node-137 192.168.0.4:9191  check
',
  name    => 'glance-registry_balancermember_glance-registry',
  order   => '01-glance-registry',
  target  => '/etc/haproxy/conf.d/090-glance-registry.cfg',
}

concat::fragment { 'glance-registry_listen_block':
  content => '
listen glance-registry
  bind 192.168.0.5:9191 
  timeout server  11m
',
  name    => 'glance-registry_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/090-glance-registry.cfg',
}

concat { '/etc/haproxy/conf.d/080-glance-api.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/080-glance-api.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/080-glance-api.cfg',
  replace        => 'true',
  warn           => 'false',
}

concat { '/etc/haproxy/conf.d/090-glance-registry.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/090-glance-registry.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/090-glance-registry.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/080-glance-api.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_080-glance-api.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_080-glance-api.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/080-glance-api.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_080-glance-api.cfg]', 'File[/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_080-glance-api.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_080-glance-api.cfg" -t',
}

exec { 'concat_/etc/haproxy/conf.d/090-glance-registry.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/090-glance-registry.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg]', 'File[/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg" -t',
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

file { '/etc/haproxy/conf.d/080-glance-api.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/080-glance-api.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/080-glance-api.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments.concat.out',
}

file { '/etc/haproxy/conf.d/090-glance-registry.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/090-glance-registry.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/090-glance-registry.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments/00_glance-api_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_glance-api_listen_block',
  backup  => 'puppet',
  content => '
listen glance-api
  bind 172.16.0.6:9292 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.5:9292 
  option  httpchk /versions
  option  httplog
  option  httpclose
  timeout server  11m
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/080-glance-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments/00_glance-api_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments/01-glance-api_glance-api_balancermember_glance-api':
  ensure  => 'file',
  alias   => 'concat_fragment_glance-api_balancermember_glance-api',
  backup  => 'puppet',
  content => '  server node-137 192.168.0.4:9292  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/080-glance-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments/01-glance-api_glance-api_balancermember_glance-api',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/080-glance-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_080-glance-api.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_080-glance-api.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_080-glance-api.cfg',
}

file { '/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments/00_glance-registry_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_glance-registry_listen_block',
  backup  => 'puppet',
  content => '
listen glance-registry
  bind 192.168.0.5:9191 
  timeout server  11m
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/090-glance-registry.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments/00_glance-registry_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments/01-glance-registry_glance-registry_balancermember_glance-registry':
  ensure  => 'file',
  alias   => 'concat_fragment_glance-registry_balancermember_glance-registry',
  backup  => 'puppet',
  content => '  server node-137 192.168.0.4:9191  check
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/090-glance-registry.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments/01-glance-registry_glance-registry_balancermember_glance-registry',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/090-glance-registry.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_090-glance-registry.cfg',
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

haproxy::balancermember::collect_exported { 'glance-api':
  name => 'glance-api',
}

haproxy::balancermember::collect_exported { 'glance-registry':
  name => 'glance-registry',
}

haproxy::balancermember { 'glance-api':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => '192.168.0.4',
  listening_service => 'glance-api',
  name              => 'glance-api',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  order             => '080',
  ports             => '9292',
  server_names      => 'node-137',
  use_include       => 'true',
}

haproxy::balancermember { 'glance-registry':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => '192.168.0.4',
  listening_service => 'glance-registry',
  name              => 'glance-registry',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check',
  order             => '090',
  ports             => '9191',
  server_names      => 'node-137',
  use_include       => 'true',
}

haproxy::listen { 'glance-api':
  bind             => {'172.16.0.6:9292' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '192.168.0.5:9292' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'glance-api',
  notify           => 'Exec[haproxy-restart]',
  options          => {'option' => ['httpchk /versions', 'httplog', 'httpclose'], 'timeout server' => '11m'},
  order            => '080',
  use_include      => 'true',
}

haproxy::listen { 'glance-registry':
  bind             => {'192.168.0.5:9191' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'glance-registry',
  notify           => 'Exec[haproxy-restart]',
  options          => {'timeout server' => '11m'},
  order            => '090',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'glance-api':
  balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  balancermember_port    => '9292',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'option' => ['httpchk /versions', 'httplog', 'httpclose'], 'timeout server' => '11m'},
  internal               => 'true',
  internal_virtual_ip    => '192.168.0.5',
  ipaddresses            => '192.168.0.4',
  listen_port            => '9292',
  name                   => 'glance-api',
  order                  => '080',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '172.16.0.6',
  require_service        => 'glance-api',
  server_names           => 'node-137',
}

openstack::ha::haproxy_service { 'glance-registry':
  balancermember_options => 'check',
  balancermember_port    => '9191',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'timeout server' => '11m'},
  internal               => 'true',
  internal_virtual_ip    => '192.168.0.5',
  ipaddresses            => '192.168.0.4',
  listen_port            => '9191',
  name                   => 'glance-registry',
  order                  => '090',
  public                 => 'false',
  public_ssl             => 'false',
  public_virtual_ip      => '172.16.0.6',
  server_names           => 'node-137',
}

stage { 'main':
  name => 'main',
}

