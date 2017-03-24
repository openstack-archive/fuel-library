class fuel::cobbler(
  $repo_root                     = $::fuel::params::repo_root,
  $cobbler_user                  = $::fuel::params::cobbler_user,
  $cobbler_password              = $::fuel::params::cobbler_password,
  $bootstrap_path,
  $bootstrap_meta,
  # network interface configuration timeout (in seconds)
  $bootstrap_ethdevice_timeout   = $::fuel::params::bootstrap_ethdevice_timeout,
  $bootstrap_profile             = $::fuel::params::bootstrap_profile,
  $centos_repos                  = $::fuel::params::centos_repos,
  $ks_system_timezone            = $::fuel::params::ks_system_timezone,
  $server                        = $::fuel::params::cobbler_host,
  $name_server                   = $::fuel::params::cobbler_host,
  $next_server                   = $::fuel::params::cobbler_host,
  $dns_upstream                  = $::fuel::params::dns_upstream,
  $dns_domain                    = $::fuel::params::dns_domain,
  $dns_search                    = $::fuel::params::dns_search,
  $mco_user                      = $::fuel::params::mco_user,
  $mco_pass                      = $::fuel::params::mco_password,
  $dhcp_ipaddress                = $::fuel::params::dhcp_ipaddress,
  $nailgun_api_url               = "http://${::fuel::params::nailgun_host}:${::fuel::params::nailgun_port}/api",
  # default password is 'r00tme'
  $ks_encrypted_root_password    = $::fuel::params::ks_encrypted_root_password,
  ) inherits fuel::params {

  anchor { 'nailgun-cobbler-begin': }
  anchor { 'nailgun-cobbler-end': }

  Anchor<| title == 'nailgun-cobbler-begin' |> ->
  Class['::cobbler'] ->
  Anchor<| title == 'nailgun-cobbler-end' |>

  $real_server = $next_server

  $fence_ssh_source = 'puppet:///modules/fuel/cobbler/fence_ssh.centos7.py'

  class { '::cobbler':
    server           => $server,
    domain_name      => $domain_name,
    dns_upstream     => $dns_upstream,
    dns_domain       => $dns_domain,
    dns_search       => $dns_search,
    name_server      => $name_server,
    next_server      => $next_server,
    dhcp_ipaddress   => $dhcp_ipaddress,
    cobbler_user     => $cobbler_user,
    cobbler_password => $cobbler_password,
    pxetimeout       => '50'
  }

  file { '/etc/cobbler/power/fence_ssh.template':
    content => template('fuel/cobbler/fence_ssh.template.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Class['::cobbler::server'],
  }

  file { '/usr/sbin/fence_ssh':
    source  => $fence_ssh_source,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Class['::cobbler::server'],
  }

  cobbler_distro { 'ubuntu_bootstrap':
    kernel    => "${bootstrap_path}/vmlinuz",
    initrd    => "${bootstrap_path}/initrd.img",
    arch      => 'x86_64',
    breed     => 'ubuntu',
    osversion => 'xenial',
    ksmeta    => '',
    require   => Class['::cobbler::server'],
  }

  cobbler_profile { 'ubuntu_bootstrap':
    distro    => 'ubuntu_bootstrap',
    menu      => true,
    kickstart => '',
    kopts     => extend_kopts($bootstrap_meta['extend_kopts'], "console=ttyS0,9600 console=tty0 panic=60 ethdevice-timeout=${bootstrap_ethdevice_timeout} boot=live toram components fetch=http://${server}:8080/bootstraps/active_bootstrap/root.squashfs biosdevname=0 url=${nailgun_api_url} mco_user=${mco_user} mco_pass=${mco_pass} ip=frommedia"),
    ksmeta    => '',
    server    => $real_server,
    require   => Cobbler_distro['ubuntu_bootstrap'],
  }

  exec { 'cobbler_system_add_default':
    command => "cobbler system add --name=default \
    --profile=${bootstrap_profile} --netboot-enabled=True",
    onlyif  => 'test -z `cobbler system find --name=default`',
    require => Cobbler_profile[$bootstrap_profile],
  }

  exec { 'cobbler_system_edit_default':
    command => "cobbler system edit --name=default \
    --profile=${bootstrap_profile} --netboot-enabled=True",
    unless  => "cobbler system report --name default 2>/dev/null | grep -q -E '^Profile\\s*:\\s*${bootstrap_profile}'",
    require => Cobbler_profile[$bootstrap_profile],
  }

  exec { 'nailgun_cobbler_sync':
    command     => 'cobbler sync',
    refreshonly => true,
  }

  Exec['cobbler_system_add_default'] ~> Exec['nailgun_cobbler_sync']
  Exec['cobbler_system_edit_default'] ~> Exec['nailgun_cobbler_sync']
  Cobbler_profile<| |> ~> Exec['nailgun_cobbler_sync']

  #FIXME(mattymo): move pubkey to astute fact or download it
  exec { 'cp /root/.ssh/id_rsa.pub /etc/cobbler/authorized_keys':
    command => 'cp /root/.ssh/id_rsa.pub /etc/cobbler/authorized_keys',
    creates => '/etc/cobbler/authorized_keys',
    require => Class['::cobbler::server'],
  }

  file { '/etc/dnsmasq.conf':
    ensure => link,
    target => '/etc/cobbler.dnsmasq.conf',
  }

  file { ['/var/log/cobbler/anamon',
          '/var/log/cobbler/kicklog',
          '/var/log/cobbler/syslog',
          '/var/log/cobbler/tasks'] :
    ensure  => directory,
    require => Class['::cobbler::server'],
  }

}
