# Install and configures cobbler
class nailgun::cobbler(
  $cobbler_user                  = $::nailgun::params::cobbler_user,
  $cobbler_password              = $::nailgun::params::cobbler_password,
  $bootstrap_flavor              = $::nailgun::params::bootstrap_flavor,
  # network interface configuration timeout (in seconds)
  $bootstrap_ethdevice_timeout   = $::nailgun::params::bootstrap_ethdevice_timeout,
  $centos_repos                  = $::nailgun::params::centos_repos,
  $production                    = $::nailgun::params::production,
  $gem_source                    = $::nailgun::params::gem_source,
  $ks_system_timezone            = $::nailgun::params::ks_system_timezone,
  $server                        = $::nailgun::params::cobbler_host,
  $name_server                   = $::nailgun::params::cobbler_host,
  $next_server                   = $::nailgun::params::cobbler_host,
  $dns_upstream                  = $::nailgun::params::dns_upstream,
  $dns_domain                    = $::nailgun::params::dhs_domain,
  $dns_search                    = $::nailgun::params::dns_search,

  $mco_user                      = $::nailgun::params::mco_user,
  $mco_pass                      = $::nailgun::params::mco_pass,
  $dhcp_start_address,
  $dhcp_end_address,
  $dhcp_netmask,
  $dhcp_gateway                  = $::ipaddress,
  $dhcp_interface,
  $nailgun_api_url               = $::nailgun::params::nailgun_api_url,
  $ks_encrypted_root_password    = $::nailgun::params::ks_encrypted_root_password,
  ) inherits nailgun::params {

  anchor { 'nailgun-cobbler-begin': }
  anchor { 'nailgun-cobbler-end': }

  Anchor<| title == 'nailgun-cobbler-begin' |> ->
  Class['::cobbler'] ->
  Anchor<| title == 'nailgun-cobbler-end' |>

  #Set real_server so Cobbler identifies its own IP correctly in Docker
  $real_server = $next_server

  $bootstrap_profile = $bootstrap_flavor ? {
    /(?i)centos/                 => 'bootstrap',
    /(?i)ubuntu/                 => 'ubuntu_bootstrap',
    default                      => 'bootstrap',
  }

  class { '::cobbler':
    server             => $server,
    production         => $production,
    domain_name        => $domain_name,
    dns_upstream       => $dns_upstream,
    dns_domain         => $dns_domain,
    dns_search         => $dns_search,
    name_server        => $name_server,
    next_server        => $next_server,
    dhcp_start_address => $dhcp_start_address,
    dhcp_end_address   => $dhcp_end_address,
    dhcp_netmask       => $dhcp_netmask,
    dhcp_gateway       => $dhcp_gateway,
    dhcp_interface     => $dhcp_interface,
    cobbler_user       => $cobbler_user,
    cobbler_password   => $cobbler_password,
    pxetimeout         => '50'
  }

  # ADDING send2syslog.py SCRIPT AND CORRESPONDING SNIPPET

  package { 'send2syslog':
    ensure => installed,
  }

  file { '/var/www/cobbler/aux/send2syslog.py':
    ensure  => link,
    target  => '/usr/bin/send2syslog.py',
    require => [
                Class['::cobbler::server'],
                Package['send2syslog']]
  }

  file { '/etc/cobbler/power/fence_ssh.template':
    content => template('nailgun/cobbler/fence_ssh.template.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Class['::cobbler::server'],
  }

  file { '/usr/sbin/fence_ssh':
    content => template('nailgun/cobbler/fence_ssh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Class['::cobbler::server'],
  }

  # THIS VARIABLE IS NEEDED FOR TEMPLATING centos-x86_64.ks
  $ks_repo = $centos_repos

  case $production {
    'prod', 'docker': {

      file { '/var/lib/cobbler/kickstarts/centos-x86_64.ks':
        content => template('cobbler/kickstart/centos.ks.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Class['::cobbler::server'],
      } ->

      cobbler_distro { 'centos-x86_64':
        kernel    => "${repo_root}/centos/x86_64/isolinux/vmlinuz",
        initrd    => "${repo_root}/centos/x86_64/isolinux/initrd.img",
        arch      => 'x86_64',
        breed     => 'redhat',
        osversion => 'rhel6',
        ksmeta    => 'tree=http://@@server@@:8080/centos/x86_64/',
        require   => Class['::cobbler::server'],
      }

      file { '/var/lib/cobbler/kickstarts/ubuntu-amd64.preseed':
        content => template('cobbler/preseed/ubuntu-1404.preseed.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Class['::cobbler::server'],
      } ->

      cobbler_distro { 'ubuntu_1404_x86_64':
        kernel    => "${repo_root}/ubuntu/x86_64/images/linux",
        initrd    => "${repo_root}/ubuntu/x86_64/images/initrd.gz",
        arch      => 'x86_64',
        breed     => 'ubuntu',
        osversion => 'trusty',
        ksmeta    => '',
        require   => Class['::cobbler::server'],
      }

      cobbler_profile { 'centos-x86_64':
        kickstart => '/var/lib/cobbler/kickstarts/centos-x86_64.ks',
        kopts     => 'biosdevname=0 sshd=1 dhcptimeout=120',
        distro    => 'centos-x86_64',
        ksmeta    => '',
        menu      => false,
        server    => $real_server,
        require   => Cobbler_distro['centos-x86_64'],
      }

      cobbler_profile { 'ubuntu_1404_x86_64':
        kickstart => '/var/lib/cobbler/kickstarts/ubuntu-amd64.preseed',
        kopts     => 'net.ifnames=0 biosdevname=0 netcfg/choose_interface=eth0 netcfg/dhcp_timeout=120 netcfg/link_detection_timeout=20',
        distro    => 'ubuntu_1404_x86_64',
        ksmeta    => '',
        menu      => false,
        server    => $real_server,
        require   => Cobbler_distro['ubuntu_1404_x86_64'],
      }

      cobbler_distro { 'bootstrap':
        kernel    => "${repo_root}/bootstrap/linux",
        initrd    => "${repo_root}/bootstrap/initramfs.img",
        arch      => 'x86_64',
        breed     => 'redhat',
        osversion => 'rhel6',
        ksmeta    => '',
        require   => Class['::cobbler::server'],
      }

      cobbler_distro { 'ubuntu_bootstrap':
        kernel    => "${repo_root}/bootstrap/ubuntu/linux",
        initrd    => "${repo_root}/bootstrap/ubuntu/initramfs.img",
        arch      => 'x86_64',
        breed     => 'ubuntu',
        osversion => 'trusty',
        ksmeta    => '',
        require   => Class['::cobbler::server'],
      }

      cobbler_profile { 'bootstrap':
        distro    => 'bootstrap',
        menu      => true,
        kickstart => '',
        kopts     => "intel_pstate=disable console=ttyS0,9600 console=tty0 biosdevname=0 url=${nailgun_api_url} mco_user=${mco_user} mco_pass=${mco_pass}",
        ksmeta    => '',
        server    => $real_server,
        require   => Cobbler_distro['bootstrap'],
      }

      cobbler_profile { 'ubuntu_bootstrap':
        distro    => 'ubuntu_bootstrap',
        menu      => true,
        kickstart => '',
        kopts     => "console=ttyS0,9600 console=tty0 panic=60 ethdevice-timeout=${bootstrap_ethdevice_timeout} boot=live toram components fetch=http://${server}:8080/bootstrap/ubuntu/root.squashfs biosdevname=0 url=${nailgun_api_url} mco_user=${mco_user} mco_pass=${mco_pass}",
        ksmeta    => '',
        server    => $real_server,
        require   => Cobbler_distro['ubuntu_bootstrap'],
      }

      if str2bool($::is_virtual) {  class { 'cobbler::checksum_bootpc': } }

      exec { 'cobbler_system_add_default':
        command => "cobbler system add --name=default \
                    --profile=${bootstrap_profile} --netboot-enabled=True",
        onlyif  => 'test -z `cobbler system find --name=default`',
        require => Cobbler_profile[$bootstrap_profile],
      }

      exec { 'cobbler_system_edit_default':
        command => "cobbler system edit --name=default \
                    --profile=${bootstrap_profile} --netboot-enabled=True",
        unless => "cobbler system report --name default 2>/dev/null | grep -q -E '^Profile\\s*:\\s*${bootstrap_profile}'",
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
    }
    'docker-build': {
      notify { 'Not adding cobbler profiles during docker build.': }
    }
    default: {
      fail("Unsupported production mode: ${production}.")
    }
  }
}
