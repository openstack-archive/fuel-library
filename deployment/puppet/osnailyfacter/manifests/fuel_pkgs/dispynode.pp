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
    $fqdn = hiera(fqdn)
    $ns             = hiera_hash(network_scheme, {})
    $admin_net      = split($ns['endpoints']['br-fw-admin']['IP'][0], '/')
    $admin_iface_ip = $admin_net[0]
    $su             = '/bin/su'
  }

  group {$user:
    ensure => present,
  } ->
  user {$user:
    ensure => present,
    gid    => $user
  } ->
  file {$workdir:
    ensure => 'directory',
    owner  => 'dispy',
    group  => 'dispy',
    mode   => '0750'
  }

  package {'python-dispy':
    ensure => installed,
    require => User['dispy']
  }

  file {$init_service:
    ensure  => present,
    content => template('osnailyfacter/dispynode.service.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    }->
    file {$init_serv_link:
      ensure => 'link',
      target => $init_service,
    }->

    service {$project:
      ensure => 'running'
    }
}
