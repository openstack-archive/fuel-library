class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Openstack::Ha::Haproxy_restart':
  name => 'Openstack::Ha::Haproxy_restart',
}

class { 'Openstack::Ha::Neutron':
  internal_virtual_ip => '192.168.0.7',
  ipaddresses         => '192.168.0.3',
  name                => 'Openstack::Ha::Neutron',
  public_ssl          => 'true',
  public_virtual_ip   => '172.16.0.3',
  server_names        => 'node-125',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

concat::fragment { 'neutron_balancermember_neutron':
  ensure  => 'present',
  content => '  server node-125 192.168.0.3:9696  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  name    => 'neutron_balancermember_neutron',
  order   => '01-neutron',
  target  => '/etc/haproxy/conf.d/085-neutron.cfg',
}

concat::fragment { 'neutron_listen_block':
  content => '
listen neutron
  bind 172.16.0.3:9696 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.7:9696 
  option  httpchk
  option  httplog
  option  httpclose
',
  name    => 'neutron_listen_block',
  order   => '00',
  target  => '/etc/haproxy/conf.d/085-neutron.cfg',
}

concat { '/etc/haproxy/conf.d/085-neutron.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/conf.d/085-neutron.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/conf.d/085-neutron.cfg',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/haproxy/conf.d/085-neutron.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_conf.d_085-neutron.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_085-neutron.cfg"',
  notify    => 'File[/etc/haproxy/conf.d/085-neutron.cfg]',
  require   => ['File[/tmp//_etc_haproxy_conf.d_085-neutron.cfg]', 'File[/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments]', 'File[/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_conf.d_085-neutron.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_conf.d_085-neutron.cfg" -t',
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

file { '/etc/haproxy/conf.d/085-neutron.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/conf.d/085-neutron.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/conf.d/085-neutron.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments/00_neutron_listen_block':
  ensure  => 'file',
  alias   => 'concat_fragment_neutron_listen_block',
  backup  => 'puppet',
  content => '
listen neutron
  bind 172.16.0.3:9696 ssl crt /var/lib/astute/haproxy/public_haproxy.pem
  bind 192.168.0.7:9696 
  option  httpchk
  option  httplog
  option  httpclose
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/085-neutron.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments/00_neutron_listen_block',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments/01-neutron_neutron_balancermember_neutron':
  ensure  => 'file',
  alias   => 'concat_fragment_neutron_balancermember_neutron',
  backup  => 'puppet',
  content => '  server node-125 192.168.0.3:9696  check inter 10s fastinter 2s downinter 3s rise 3 fall 3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/085-neutron.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments/01-neutron_neutron_balancermember_neutron',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/conf.d/085-neutron.cfg]',
  path    => '/tmp//_etc_haproxy_conf.d_085-neutron.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_conf.d_085-neutron.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_conf.d_085-neutron.cfg',
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

haproxy::balancermember::collect_exported { 'neutron':
  name => 'neutron',
}

haproxy::balancermember { 'neutron':
  ensure            => 'present',
  define_backups    => 'false',
  define_cookies    => 'false',
  ipaddresses       => '192.168.0.3',
  listening_service => 'neutron',
  name              => 'neutron',
  notify            => 'Exec[haproxy-restart]',
  options           => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  order             => '085',
  ports             => '9696',
  server_names      => 'node-125',
  use_include       => 'true',
}

haproxy::listen { 'neutron':
  bind             => {'172.16.0.3:9696' => ['ssl', 'crt', '/var/lib/astute/haproxy/public_haproxy.pem'], '192.168.0.7:9696' => ''},
  bind_options     => '',
  collect_exported => 'true',
  name             => 'neutron',
  notify           => 'Exec[haproxy-restart]',
  options          => {'option' => ['httpchk', 'httplog', 'httpclose']},
  order            => '085',
  use_include      => 'true',
}

openstack::ha::haproxy_service { 'neutron':
  balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  balancermember_port    => '9696',
  before_start           => 'false',
  define_backups         => 'false',
  define_cookies         => 'false',
  haproxy_config_options => {'option' => ['httpchk', 'httplog', 'httpclose']},
  internal               => 'true',
  internal_virtual_ip    => '192.168.0.7',
  ipaddresses            => '192.168.0.3',
  listen_port            => '9696',
  name                   => 'neutron',
  order                  => '085',
  public                 => 'true',
  public_ssl             => 'true',
  public_virtual_ip      => '172.16.0.3',
  server_names           => 'node-125',
}

stage { 'main':
  name => 'main',
}

