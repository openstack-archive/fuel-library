class nailgun::cobbler(
  $cobbler_user = "cobbler",
  $cobbler_password = "cobbler",
  $centos_repos,
  $production,
  $gem_source,

  $ks_system_timezone         = "Etc/UTC",
  $server = $::ipaddress,
  $name_server = $::ipaddress,
  $next_server = $::ipaddress,
  $dns_upstream = '8.8.8.8',
  $dns_domain = 'domain.tld',
  $dns_search = 'domain.tld',

  $mco_user = 'mcollective',
  $mco_pass = 'marionette',

  $dhcp_start_address,
  $dhcp_end_address,
  $dhcp_netmask,
  $dhcp_gateway = $ipaddress,
  $dhcp_interface,
  $nailgun_api_url = "http://${::ipaddress}:8000/api",
  # default password is 'r00tme'
  $ks_encrypted_root_password = "\$6\$tCD3X7ji\$1urw6qEMDkVxOkD33b4TpQAjRiCeDZx0jmgMhDYhfB9KuGfqO9OcMaKyUxnGGWslEDQ4HxTw7vcAMP85NxQe61",

  ){

  anchor { "nailgun-cobbler-begin": }
  anchor { "nailgun-cobbler-end": }

  Anchor<| title == "nailgun-cobbler-begin" |> ->
  Class["::cobbler"] ->
  Anchor<| title == "nailgun-cobbler-end" |>

  #Set real_server so Cobbler identifies its own IP correctly in Docker
  $real_server = $next_server

  class { "::cobbler":
    server              => $server,
    production          => $production,

    domain_name         => $domain_name,
    dns_upstream        => $dns_upstream,
    dns_domain          => $dns_domain,
    dns_search          => $dns_search,
    name_server         => $name_server,
    next_server         => $next_server,

    dhcp_start_address  => $dhcp_start_address,
    dhcp_end_address    => $dhcp_end_address,
    dhcp_netmask        => $dhcp_netmask,
    dhcp_gateway        => $dhcp_gateway,
    dhcp_interface      => $dhcp_interface,

    cobbler_user        => $cobbler_user,
    cobbler_password    => $cobbler_password,

    pxetimeout          => '50'
  }

  # ADDING send2syslog.py SCRIPT AND CORRESPONDING SNIPPET

  package { "send2syslog":
    ensure => installed,
  }

  file { "/var/www/cobbler/aux/send2syslog.py":
    ensure => '/usr/bin/send2syslog.py',
    require => [
               Class["::cobbler::server"],
               Package['send2syslog'],
               ]
  }

  file { "/etc/cobbler/power/fence_ssh.template":
    content => template("nailgun/cobbler/fence_ssh.template.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => Class["::cobbler::server"],
  }

  file { "/usr/sbin/fence_ssh":
    content => template("nailgun/cobbler/fence_ssh.erb"),
    owner => 'root',
    group => 'root',
    mode => 0755,
    require => Class["::cobbler::server"],
  }

  # THIS VARIABLE IS NEEDED FOR TEMPLATING centos-x86_64.ks
  $ks_repo = $centos_repos

  case $production {
    'prod', 'docker': {

      file { "/var/lib/cobbler/kickstarts/centos-x86_64.ks":
        content => template("cobbler/kickstart/centos.ks.erb"),
        owner => root,
        group => root,
        mode => 0644,
        require => Class["::cobbler::server"],
      } ->

      cobbler_distro { "centos-x86_64":
        kernel => "${repo_root}/centos/fuelweb/x86_64/isolinux/vmlinuz",
        initrd => "${repo_root}/centos/fuelweb/x86_64/isolinux/initrd.img",
        arch => "x86_64",
        breed => "redhat",
        osversion => "rhel6",
        ksmeta => "tree=http://@@server@@:8080/centos/fuelweb/x86_64/",
        require => Class["::cobbler::server"],
      }

      file { "/var/lib/cobbler/kickstarts/ubuntu-amd64.preseed":
        content => template("cobbler/preseed/ubuntu-1204.preseed.erb"),
        owner => root,
        group => root,
        mode => 0644,
        require => Class["::cobbler::server"],
      } ->

      cobbler_distro { "ubuntu_1204_x86_64":
        kernel => "${repo_root}/ubuntu/fuelweb/x86_64/images/linux",
        initrd => "${repo_root}/ubuntu/fuelweb/x86_64/images/initrd.gz",
        arch => "x86_64",
        breed => "ubuntu",
        osversion => "precise",
        ksmeta => "",
        require => Class["::cobbler::server"],
      }


      cobbler_profile { "centos-x86_64":
        kickstart => "/var/lib/cobbler/kickstarts/centos-x86_64.ks",
        kopts => "biosdevname=0 sshd=1",
        distro => "centos-x86_64",
        ksmeta => "",
        menu => true,
        server => $real_server,
        require => Cobbler_distro["centos-x86_64"],
      }

      cobbler_profile { "ubuntu_1204_x86_64":
        kickstart => "/var/lib/cobbler/kickstarts/ubuntu-amd64.preseed",
        kopts => "netcfg/choose_interface=eth0",
        distro => "ubuntu_1204_x86_64",
        ksmeta => "",
        menu => true,
        server => $real_server,
        require => Cobbler_distro["ubuntu_1204_x86_64"],
      }


      cobbler_distro { "bootstrap":
        kernel => "${repo_root}/bootstrap/linux",
        initrd => "${repo_root}/bootstrap/initramfs.img",
        arch => "x86_64",
        breed => "redhat",
        osversion => "rhel6",
        ksmeta => "",
        require => Class["::cobbler::server"],
      }

      cobbler_profile { "bootstrap":
        distro => "bootstrap",
        menu => true,
        kickstart => "",
        kopts => "biosdevname=0 url=http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/api mco_user=${mco_user} mco_pass=${mco_pass}",
        ksmeta => "",
        server => $real_server,
        require => Cobbler_distro["bootstrap"],
      }

      if str2bool($::is_virtual) {  class { cobbler::checksum_bootpc: } }

      exec { "cobbler_system_add_default":
        command => "cobbler system add --name=default \
        --profile=bootstrap --netboot-enabled=True",
        onlyif => "test -z `cobbler system find --name=default`",
        require => Cobbler_profile["bootstrap"],
      }

      exec { "cobbler_system_edit_default":
        command => "cobbler system edit --name=default \
        --profile=bootstrap --netboot-enabled=True",
        onlyif => "test ! -z `cobbler system find --name=default`",
        require => Cobbler_profile["bootstrap"],
      }

      exec { "nailgun_cobbler_sync":
        command => "cobbler sync",
        refreshonly => true,
      }

      Exec["cobbler_system_add_default"] ~> Exec["nailgun_cobbler_sync"]
      Exec["cobbler_system_edit_default"] ~> Exec["nailgun_cobbler_sync"]
      Cobbler_profile<| |> ~> Exec["nailgun_cobbler_sync"]
      #TODO(mattymo): refactor this into cobbler module and use OS-dependent
      #directories
      file { ['/etc/httpd', '/etc/httpd/conf.d/']:
        ensure => 'directory',
      }
      file { '/etc/httpd/conf.d/nailgun.conf':
        content => template('nailgun/httpd_nailgun.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
      }

      #FIXME(mattymo): move pubkey to astute fact or download it
      exec { "cp /root/.ssh/id_rsa.pub /etc/cobbler/authorized_keys":
        command => "cp /root/.ssh/id_rsa.pub /etc/cobbler/authorized_keys",
        creates => "/etc/cobbler/authorized_keys",
        require => Class["::cobbler::server"],
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
