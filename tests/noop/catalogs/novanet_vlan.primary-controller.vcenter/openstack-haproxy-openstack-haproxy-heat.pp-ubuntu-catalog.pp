class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Haproxy_restart':
  name => 'Openstack::Ha::Haproxy_restart',
}

class { 'Openstack::Ha::Heat':
  internal_virtual_ip => '172.16.1.2',
  ipaddresses         => ['172.16.1.6', '172.16.1.3', '172.16.1.5'],
  name                => 'Openstack::Ha::Heat',
  public_ssl          => 'true',
  public_virtual_ip   => '172.16.0.3',
  server_names        => ['node-5', 'node-6', 'node-3'],
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

concat::fragment { 'heat-api-cfn_balancermember_heat-api-cfn':
  ensure  => 'present',
  content => '  server node-5 172.16.1.6:8000  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
  server node-6 172.16.1.3:8000  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
  server node-3 172.16.1.5:8000  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  name    => 'heat-api-cfn_balancermember_heat-api-cfn',
  order   => '01-heat-api-cfn',
  target  => '/etc/haproxy/conf.d/161-heat-api-cfn.cfg',
}

concat::fragment { 'heat-api-cfn_listen_block':
  content => '
listen heat-api-cfn
  bind 172.16.0.3:8000 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 172.16.1.2:8000 
  option  httpchk
  option  httplog
  option  httpclose
  timeout server  660s
',
  name    => 'heat-api-cfn_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/161-heat-api-cfn.cfg',
}

concat::fragment { 'heat-api-cloudwatch_balancermember_heat-api-cloudwatch':
  ensure  => 'present',
  content => '  server node-5 172.16.1.6:8003  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
  server node-6 172.16.1.3:8003  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
  server node-3 172.16.1.5:8003  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  name    => 'heat-api-cloudwatch_balancermember_heat-api-cloudwatch',
  order   => '01-heat-api-cloudwatch',
  target  => '/etc/haproxy/conf.d/162-heat-api-cloudwatch.cfg',
}

concat::fragment { 'heat-api-cloudwatch_listen_block':
  content => '
listen heat-api-cloudwatch
  bind 172.16.0.3:8003 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 172.16.1.2:8003 
  option  httpchk
  option  httplog
  option  httpclose
  timeout server  660s
',
  name    => 'heat-api-cloudwatch_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/162-heat-api-cloudwatch.cfg',
}

concat::fragment { 'heat-api_balancermember_heat-api':
  ensure  => 'present',
  content => '  server node-5 172.16.1.6:8004  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
  server node-6 172.16.1.3:8004  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
  server node-3 172.16.1.5:8004  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  name    => 'heat-api_balancermember_heat-api',
  order   => '01-heat-api',
  target  => '/etc/haproxy/conf.d/160-heat-api.cfg',
}

concat::fragment { 'heat-api_listen_block':
  content => '
listen heat-api
  bind 172.16.0.3:8004 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 172.16.1.2:8004 
  http-request  set-header X-Forwarded-Proto https if { ssl_fc }
  option  httpchk
  option  httplog
  option  httpclose
  timeout server  660s
',
  name    => 'heat-api_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/160-heat-api.cfg',
}

concat { '/etc/haproxy/conf.d/160-heat-api.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/160-heat-api.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/160-heat-api.cfg',
  replace        => 'true',
  warn           => 'false',
}

concat { '/etc/haproxy/conf.d/161-heat-api-cfn.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/161-heat-api-cfn.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/161-heat-api-cfn.cfg',
  replace        => 'true',
  warn           => 'false',
}

concat { '/etc/haproxy/conf.d/162-heat-api-cloudwatch.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/162-heat-api-cloudwatch.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/162-heat-api-cloudwatch.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/160-heat-api.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_160-heat-api.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_160-heat-api.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/160-heat-api.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_160-heat-api.cfg]', 'File[/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_160-heat-api.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_160-heat-api.cfg" -t',
}

exec { 'concat_/etc/haproxy/conf.d/161-heat-api-cfn.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/161-heat-api-cfn.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg]', 'File[/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg" -t',
}

exec { 'concat_/etc/haproxy/conf.d/162-heat-api-cloudwatch.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/162-heat-api-cloudwatch.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg]', 'File[/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg" -t',
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

file { '/etc/haproxy/conf.d/160-heat-api.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/160-heat-api.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/160-heat-api.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments.concat.out',
}

file { '/etc/haproxy/conf.d/161-heat-api-cfn.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/161-heat-api-cfn.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/161-heat-api-cfn.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments.concat.out',
}

file { '/etc/haproxy/conf.d/162-heat-api-cloudwatch.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/162-heat-api-cloudwatch.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/162-heat-api-cloudwatch.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments/00_heat-api_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_heat-api_listen_block',
  backup  => 'puppet',
  content => '
listen heat-api
  bind 172.16.0.3:8004 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 172.16.1.2:8004 
  http-request  set-header X-Forwarded-Proto https if { ssl_fc }
  option  httpchk
  option  httplog
  option  httpclose
  timeout server  660s
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/160-heat-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments/00_heat-api_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments/01-heat-api_heat-api_balancermember_heat-api':
  ensure  => 'file',
  alias   => 'concat_fragment_heat-api_balancermember_heat-api',
  backup  => 'puppet',
  content => '  server node-5 172.16.1.6:8004  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
  server node-6 172.16.1.3:8004  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
  server node-3 172.16.1.5:8004  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/160-heat-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments/01-heat-api_heat-api_balancermember_heat-api',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/160-heat-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_160-heat-api.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_160-heat-api.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_160-heat-api.cfg',
}

file { '/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments/00_heat-api-cfn_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_heat-api-cfn_listen_block',
  backup  => 'puppet',
  content => '
listen heat-api-cfn
  bind 172.16.0.3:8000 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 172.16.1.2:8000 
  option  httpchk
  option  httplog
  option  httpclose
  timeout server  660s
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/161-heat-api-cfn.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments/00_heat-api-cfn_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments/01-heat-api-cfn_heat-api-cfn_balancermember_heat-api-cfn':
  ensure  => 'file',
  alias   => 'concat_fragment_heat-api-cfn_balancermember_heat-api-cfn',
  backup  => 'puppet',
  content => '  server node-5 172.16.1.6:8000  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
  server node-6 172.16.1.3:8000  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
  server node-3 172.16.1.5:8000  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/161-heat-api-cfn.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments/01-heat-api-cfn_heat-api-cfn_balancermember_heat-api-cfn',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/161-heat-api-cfn.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_161-heat-api-cfn.cfg',
}

file { '/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments/00_heat-api-cloudwatch_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_heat-api-cloudwatch_listen_block',
  backup  => 'puppet',
  content => '
listen heat-api-cloudwatch
  bind 172.16.0.3:8003 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 172.16.1.2:8003 
  option  httpchk
  option  httplog
  option  httpclose
  timeout server  660s
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/162-heat-api-cloudwatch.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments/00_heat-api-cloudwatch_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments/01-heat-api-cloudwatch_heat-api-cloudwatch_balancermember_heat-api-cloudwatch':
  ensure  => 'file',
  alias   => 'concat_fragment_heat-api-cloudwatch_balancermember_heat-api-cloudwatch',
  backup  => 'puppet',
  content => '  server node-5 172.16.1.6:8003  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
  server node-6 172.16.1.3:8003  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
  server node-3 172.16.1.5:8003  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/162-heat-api-cloudwatch.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments/01-heat-api-cloudwatch_heat-api-cloudwatch_balancermember_heat-api-cloudwatch',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/162-heat-api-cloudwatch.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_162-heat-api-cloudwatch.cfg',
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

haproxy::balancermember::collect_exported { 'heat-api-cfn':
  name => 'heat-api-cfn',
}

haproxy::balancermember::collect_exported { 'heat-api-cloudwatch':
  name => 'heat-api-cloudwatch',
}

haproxy::balancermember::collect_exported { 'heat-api':
  name => 'heat-api',
}

haproxy::balancermember { 'heat-api-cfn':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => ['172.16.1.6', '172.16.1.3', '172.16.1.5'],
  listening_service => 'heat-api-cfn',
  name              => 'heat-api-cfn',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  order             => '161',
  ports             => '8000',
  server_names      => ['node-5', 'node-6', 'node-3'],
  use_include       => 'true',
}

haproxy::balancermember { 'heat-api-cloudwatch':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => ['172.16.1.6', '172.16.1.3', '172.16.1.5'],
  listening_service => 'heat-api-cloudwatch',
  name              => 'heat-api-cloudwatch',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  order             => '162',
  ports             => '8003',
  server_names      => ['node-5', 'node-6', 'node-3'],
  use_include       => 'true',
}

haproxy::balancermember { 'heat-api':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => ['172.16.1.6', '172.16.1.3', '172.16.1.5'],
  listening_service => 'heat-api',
  name              => 'heat-api',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  order             => '160',
  ports             => '8004',
  server_names      => ['node-5', 'node-6', 'node-3'],
  use_include       => 'true',
}

haproxy::listen { 'heat-api-cfn':
  bind             => {'172.16.0.3:8000' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '172.16.1.2:8000' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'heat-api-cfn',
  notify           => 'Exec[haproxy-restart]',
  options          => {'option' => ['httpchk', 'httplog', 'httpclose'], 'timeout server' => '660s'},
  order            => '161',
  use_include      => 'true',
}

haproxy::listen { 'heat-api-cloudwatch':
  bind             => {'172.16.0.3:8003' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '172.16.1.2:8003' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'heat-api-cloudwatch',
  notify           => 'Exec[haproxy-restart]',
  options          => {'option' => ['httpchk', 'httplog', 'httpclose'], 'timeout server' => '660s'},
  order            => '162',
  use_include      => 'true',
}

haproxy::listen { 'heat-api':
  bind             => {'172.16.0.3:8004' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '172.16.1.2:8004' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'heat-api',
  notify           => 'Exec[haproxy-restart]',
  options          => {'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }', 'option' => ['httpchk', 'httplog', 'httpclose'], 'timeout server' => '660s'},
  order            => '160',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'heat-api-cfn':
  balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  balancermember_port    => '8000',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'option' => ['httpchk', 'httplog', 'httpclose'], 'timeout server' => '660s'},
  internal               => 'true',
  internal_virtual_ip    => '172.16.1.2',
  ipaddresses            => ['172.16.1.6', '172.16.1.3', '172.16.1.5'],
  listen_port            => '8000',
  name                   => 'heat-api-cfn',
  order                  => '161',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '172.16.0.3',
  require_service        => 'heat-api',
  server_names           => ['node-5', 'node-6', 'node-3'],
}

openstack::ha::haproxy_service { 'heat-api-cloudwatch':
  balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  balancermember_port    => '8003',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'option' => ['httpchk', 'httplog', 'httpclose'], 'timeout server' => '660s'},
  internal               => 'true',
  internal_virtual_ip    => '172.16.1.2',
  ipaddresses            => ['172.16.1.6', '172.16.1.3', '172.16.1.5'],
  listen_port            => '8003',
  name                   => 'heat-api-cloudwatch',
  order                  => '162',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '172.16.0.3',
  require_service        => 'heat-api',
  server_names           => ['node-5', 'node-6', 'node-3'],
}

openstack::ha::haproxy_service { 'heat-api':
  balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  balancermember_port    => '8004',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }', 'option' => ['httpchk', 'httplog', 'httpclose'], 'timeout server' => '660s'},
  internal               => 'true',
  internal_virtual_ip    => '172.16.1.2',
  ipaddresses            => ['172.16.1.6', '172.16.1.3', '172.16.1.5'],
  listen_port            => '8004',
  name                   => 'heat-api',
  order                  => '160',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '172.16.0.3',
  require_service        => 'heat-api',
  server_names           => ['node-5', 'node-6', 'node-3'],
}

stage { 'main':
  name => 'main',
}

