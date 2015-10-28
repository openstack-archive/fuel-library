class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Haproxy_restart':
  name => 'Openstack::Ha::Haproxy_restart',
}

class { 'Openstack::Ha::Nova':
  internal_virtual_ip => '10.122.12.2',
  ipaddresses         => '10.122.12.3',
  name                => 'Openstack::Ha::Nova',
  public_ssl          => 'true',
  public_virtual_ip   => '10.122.11.3',
  server_names        => 'node-1',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

concat::fragment { 'nova-api-1_balancermember_nova-api-1':
  ensure  => 'present',
  content => '  server node-1 10.122.12.3:8773  check
',
  name    => 'nova-api-1_balancermember_nova-api-1',
  order   => '01-nova-api-1',
  target  => '/etc/haproxy/conf.d/040-nova-api-1.cfg',
}

concat::fragment { 'nova-api-1_listen_block':
  content => '
listen nova-api-1
  bind 10.122.11.3:8773 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 10.122.12.2:8773 
  timeout server  600s
',
  name    => 'nova-api-1_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/040-nova-api-1.cfg',
}

concat::fragment { 'nova-api-2_balancermember_nova-api-2':
  ensure  => 'present',
  content => '  server node-1 10.122.12.3:8774  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  name    => 'nova-api-2_balancermember_nova-api-2',
  order   => '01-nova-api-2',
  target  => '/etc/haproxy/conf.d/050-nova-api-2.cfg',
}

concat::fragment { 'nova-api-2_listen_block':
  content => '
listen nova-api-2
  bind 10.122.11.3:8774 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 10.122.12.2:8774 
  option  httpchk
  option  httplog
  option  httpclose
  timeout server  600s
',
  name    => 'nova-api-2_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/050-nova-api-2.cfg',
}

concat::fragment { 'nova-metadata-api_balancermember_nova-metadata-api':
  ensure  => 'present',
  content => '  server node-1 10.122.12.3:8775  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  name    => 'nova-metadata-api_balancermember_nova-metadata-api',
  order   => '01-nova-metadata-api',
  target  => '/etc/haproxy/conf.d/060-nova-metadata-api.cfg',
}

concat::fragment { 'nova-metadata-api_listen_block':
  content => '
listen nova-metadata-api
  bind 10.122.12.2:8775 
  option  httpchk
  option  httplog
  option  httpclose
',
  name    => 'nova-metadata-api_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/060-nova-metadata-api.cfg',
}

concat::fragment { 'nova-novncproxy_balancermember_nova-novncproxy':
  ensure  => 'present',
  content => '  server node-1 10.122.12.3:6080  check
',
  name    => 'nova-novncproxy_balancermember_nova-novncproxy',
  order   => '01-nova-novncproxy',
  target  => '/etc/haproxy/conf.d/170-nova-novncproxy.cfg',
}

concat::fragment { 'nova-novncproxy_listen_block':
  content => '
listen nova-novncproxy
  bind 10.122.11.3:6080 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  balance  roundrobin
  option  httplog
',
  name    => 'nova-novncproxy_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/170-nova-novncproxy.cfg',
}

concat { '/etc/haproxy/conf.d/040-nova-api-1.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/040-nova-api-1.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/040-nova-api-1.cfg',
  replace        => 'true',
  warn           => 'false',
}

concat { '/etc/haproxy/conf.d/050-nova-api-2.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/050-nova-api-2.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/050-nova-api-2.cfg',
  replace        => 'true',
  warn           => 'false',
}

concat { '/etc/haproxy/conf.d/060-nova-metadata-api.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/060-nova-metadata-api.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/060-nova-metadata-api.cfg',
  replace        => 'true',
  warn           => 'false',
}

concat { '/etc/haproxy/conf.d/170-nova-novncproxy.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/170-nova-novncproxy.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/170-nova-novncproxy.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/040-nova-api-1.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/040-nova-api-1.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg]', 'File[/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg" -t',
}

exec { 'concat_/etc/haproxy/conf.d/050-nova-api-2.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/050-nova-api-2.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg]', 'File[/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg" -t',
}

exec { 'concat_/etc/haproxy/conf.d/060-nova-metadata-api.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/060-nova-metadata-api.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg]', 'File[/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg" -t',
}

exec { 'concat_/etc/haproxy/conf.d/170-nova-novncproxy.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/170-nova-novncproxy.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg]', 'File[/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg" -t',
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

file { '/etc/haproxy/conf.d/040-nova-api-1.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/040-nova-api-1.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/040-nova-api-1.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments.concat.out',
}

file { '/etc/haproxy/conf.d/050-nova-api-2.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/050-nova-api-2.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/050-nova-api-2.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments.concat.out',
}

file { '/etc/haproxy/conf.d/060-nova-metadata-api.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/060-nova-metadata-api.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/060-nova-metadata-api.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments.concat.out',
}

file { '/etc/haproxy/conf.d/170-nova-novncproxy.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/170-nova-novncproxy.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/170-nova-novncproxy.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments/00_nova-api-1_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_nova-api-1_listen_block',
  backup  => 'puppet',
  content => '
listen nova-api-1
  bind 10.122.11.3:8773 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 10.122.12.2:8773 
  timeout server  600s
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/040-nova-api-1.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments/00_nova-api-1_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments/01-nova-api-1_nova-api-1_balancermember_nova-api-1':
  ensure  => 'file',
  alias   => 'concat_fragment_nova-api-1_balancermember_nova-api-1',
  backup  => 'puppet',
  content => '  server node-1 10.122.12.3:8773  check
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/040-nova-api-1.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments/01-nova-api-1_nova-api-1_balancermember_nova-api-1',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/040-nova-api-1.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_040-nova-api-1.cfg',
}

file { '/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments/00_nova-api-2_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_nova-api-2_listen_block',
  backup  => 'puppet',
  content => '
listen nova-api-2
  bind 10.122.11.3:8774 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 10.122.12.2:8774 
  option  httpchk
  option  httplog
  option  httpclose
  timeout server  600s
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/050-nova-api-2.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments/00_nova-api-2_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments/01-nova-api-2_nova-api-2_balancermember_nova-api-2':
  ensure  => 'file',
  alias   => 'concat_fragment_nova-api-2_balancermember_nova-api-2',
  backup  => 'puppet',
  content => '  server node-1 10.122.12.3:8774  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/050-nova-api-2.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments/01-nova-api-2_nova-api-2_balancermember_nova-api-2',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/050-nova-api-2.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_050-nova-api-2.cfg',
}

file { '/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments/00_nova-metadata-api_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_nova-metadata-api_listen_block',
  backup  => 'puppet',
  content => '
listen nova-metadata-api
  bind 10.122.12.2:8775 
  option  httpchk
  option  httplog
  option  httpclose
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/060-nova-metadata-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments/00_nova-metadata-api_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments/01-nova-metadata-api_nova-metadata-api_balancermember_nova-metadata-api':
  ensure  => 'file',
  alias   => 'concat_fragment_nova-metadata-api_balancermember_nova-metadata-api',
  backup  => 'puppet',
  content => '  server node-1 10.122.12.3:8775  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/060-nova-metadata-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments/01-nova-metadata-api_nova-metadata-api_balancermember_nova-metadata-api',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/060-nova-metadata-api.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_060-nova-metadata-api.cfg',
}

file { '/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments/00_nova-novncproxy_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_nova-novncproxy_listen_block',
  backup  => 'puppet',
  content => '
listen nova-novncproxy
  bind 10.122.11.3:6080 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  balance  roundrobin
  option  httplog
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/170-nova-novncproxy.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments/00_nova-novncproxy_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments/01-nova-novncproxy_nova-novncproxy_balancermember_nova-novncproxy':
  ensure  => 'file',
  alias   => 'concat_fragment_nova-novncproxy_balancermember_nova-novncproxy',
  backup  => 'puppet',
  content => '  server node-1 10.122.12.3:6080  check
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/170-nova-novncproxy.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments/01-nova-novncproxy_nova-novncproxy_balancermember_nova-novncproxy',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/170-nova-novncproxy.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_170-nova-novncproxy.cfg',
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

haproxy::balancermember::collect_exported { 'nova-api-1':
  name => 'nova-api-1',
}

haproxy::balancermember::collect_exported { 'nova-api-2':
  name => 'nova-api-2',
}

haproxy::balancermember::collect_exported { 'nova-metadata-api':
  name => 'nova-metadata-api',
}

haproxy::balancermember::collect_exported { 'nova-novncproxy':
  name => 'nova-novncproxy',
}

haproxy::balancermember { 'nova-api-1':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => '10.122.12.3',
  listening_service => 'nova-api-1',
  name              => 'nova-api-1',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check',
  order             => '040',
  ports             => '8773',
  server_names      => 'node-1',
  use_include       => 'true',
}

haproxy::balancermember { 'nova-api-2':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => '10.122.12.3',
  listening_service => 'nova-api-2',
  name              => 'nova-api-2',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  order             => '050',
  ports             => '8774',
  server_names      => 'node-1',
  use_include       => 'true',
}

haproxy::balancermember { 'nova-metadata-api':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => '10.122.12.3',
  listening_service => 'nova-metadata-api',
  name              => 'nova-metadata-api',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  order             => '060',
  ports             => '8775',
  server_names      => 'node-1',
  use_include       => 'true',
}

haproxy::balancermember { 'nova-novncproxy':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => '10.122.12.3',
  listening_service => 'nova-novncproxy',
  name              => 'nova-novncproxy',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check',
  order             => '170',
  ports             => '6080',
  server_names      => 'node-1',
  use_include       => 'true',
}

haproxy::listen { 'nova-api-1':
  bind             => {'10.122.11.3:8773' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '10.122.12.2:8773' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'nova-api-1',
  notify           => 'Exec[haproxy-restart]',
  options          => {'timeout server' => '600s'},
  order            => '040',
  use_include      => 'true',
}

haproxy::listen { 'nova-api-2':
  bind             => {'10.122.11.3:8774' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '10.122.12.2:8774' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'nova-api-2',
  notify           => 'Exec[haproxy-restart]',
  options          => {'option' => ['httpchk', 'httplog', 'httpclose'], 'timeout server' => '600s'},
  order            => '050',
  use_include      => 'true',
}

haproxy::listen { 'nova-metadata-api':
  bind             => {'10.122.12.2:8775' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'nova-metadata-api',
  notify           => 'Exec[haproxy-restart]',
  options          => {'option' => ['httpchk', 'httplog', 'httpclose']},
  order            => '060',
  use_include      => 'true',
}

haproxy::listen { 'nova-novncproxy':
  bind             => {'10.122.11.3:6080' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem']},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'nova-novncproxy',
  notify           => 'Exec[haproxy-restart]',
  options          => {'balance' => 'roundrobin', 'option' => ['httplog']},
  order            => '170',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'nova-api-1':
  balancermember_options => 'check',
  balancermember_port    => '8773',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'timeout server' => '600s'},
  internal               => 'true',
  internal_virtual_ip    => '10.122.12.2',
  ipaddresses            => '10.122.12.3',
  listen_port            => '8773',
  name                   => 'nova-api-1',
  order                  => '040',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '10.122.11.3',
  require_service        => 'nova-api',
  server_names           => 'node-1',
}

openstack::ha::haproxy_service { 'nova-api-2':
  balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  balancermember_port    => '8774',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'option' => ['httpchk', 'httplog', 'httpclose'], 'timeout server' => '600s'},
  internal               => 'true',
  internal_virtual_ip    => '10.122.12.2',
  ipaddresses            => '10.122.12.3',
  listen_port            => '8774',
  name                   => 'nova-api-2',
  order                  => '050',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '10.122.11.3',
  require_service        => 'nova-api',
  server_names           => 'node-1',
}

openstack::ha::haproxy_service { 'nova-metadata-api':
  balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  balancermember_port    => '8775',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'option' => ['httpchk', 'httplog', 'httpclose']},
  internal               => 'true',
  internal_virtual_ip    => '10.122.12.2',
  ipaddresses            => '10.122.12.3',
  listen_port            => '8775',
  name                   => 'nova-metadata-api',
  order                  => '060',
  public                 => 'false',
  public_ssl             => 'false',
  public_virtual_ip      => '10.122.11.3',
  server_names           => 'node-1',
}

openstack::ha::haproxy_service { 'nova-novncproxy':
  balancermember_options => 'check',
  balancermember_port    => '6080',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'balance' => 'roundrobin', 'option' => ['httplog']},
  internal               => 'false',
  internal_virtual_ip    => '10.122.12.2',
  ipaddresses            => '10.122.12.3',
  listen_port            => '6080',
  name                   => 'nova-novncproxy',
  order                  => '170',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '10.122.11.3',
  require_service        => 'nova-vncproxy',
  server_names           => 'node-1',
}

stage { 'main':
  name => 'main',
}

