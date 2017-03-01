class osnailyfacter::fuel_pkgs::dispynode(
  $master = undef,
)
{

  notice('MODULAR: fuel_pkgs/dispynode.pp')

  $user           = 'dispy'
  $workdir        = "/var/lib/${user}"
  $project        = 'dispynode.py'
  $init_file      = "/etc/init.d/${project}"
  $init_file_conf = "/etc/init/${project}.conf"
  $init_service   = "/lib/systemd/system/${project}.service"
  $init_serv_link = "/etc/systemd/system/multi-user.target.wants/${project}.service"

  if $master {
    $hostname       = hiera(HOSTNAME)
    $domainname     = hiera(DNS_DOMAIN)
    $fqdn           = "${hostname}.${domainname}"
    $admin_iface_ip = 'localhost'
    $su             = '/usr/bin/su'
  }
  else {
    $fqdn           = hiera(fqdn)
    $ns             = hiera_hash(network_scheme, {})
    $admin_net      = split($ns['endpoints']['br-fw-admin']['IP'][0], '/')
    $admin_iface_ip = $admin_net[0]
    $su             = '/bin/su'
  }

  package {'python-dispy':
    ensure => installed,
  }

  group {'dispy_group':
    ensure => present,
    name   => $user,
  }

  user {'dispy_user':
    ensure  => present,
    name    => $user,
    gid     => $user,
    require => Group[$user]
  }

  file {'workdir':
    ensure  => 'directory',
    path    => $workdir,
    owner   => $user,
    group   => $user,
    mode    => '0750',
    require => User[$user]
  }

  file {'dispy_init':
    ensure  => present,
    path    => $init_service,
    content => template('osnailyfacter/dispynode.service.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => User[$user]
  }

  file {'dispy_init_link':
    ensure  => 'link',
    path    => $init_serv_link,
    target  => $init_service,
    require => File[$init_service]
  }

  service {'dispy_service':
    name    => $project,
    ensure  => 'running',
    require => [
                File[$init_serv_link],
                File[$workdir],
                Package['python-dispy'],
                ]
  }
}
