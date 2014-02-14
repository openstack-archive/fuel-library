class nailgun::cobbler(
  $cobbler_user = "cobbler",
  $cobbler_password = "cobbler",

#  $ubuntu_repos,
  $centos_repos,
  $gem_source,

  $ks_system_timezone         = "Etc/UTC",

  # default password is 'r00tme'
  $ks_encrypted_root_password = "\$6\$tCD3X7ji\$1urw6qEMDkVxOkD33b4TpQAjRiCeDZx0jmgMhDYhfB9KuGfqO9OcMaKyUxnGGWslEDQ4HxTw7vcAMP85NxQe61",

  ){

  anchor { "nailgun-cobbler-begin": }
  anchor { "nailgun-cobbler-end": }

  Anchor<| title == "nailgun-cobbler-begin" |> ->
  Class["::cobbler"] ->
  Anchor<| title == "nailgun-cobbler-end" |>

  class { "::cobbler":
    server              => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],

    domain_name         => $domain,
    name_server         => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    next_server         => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],

    dhcp_start_address  => $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_start'],
    dhcp_end_address    => $::fuel_settings['ADMIN_NETWORK']['dhcp_pool_end'],
    dhcp_netmask        => $::fuel_settings['ADMIN_NETWORK']['netmask'],
    dhcp_gateway        => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    dhcp_interface      => $::fuel_settings['ADMIN_NETWORK']['interface'],

    cobbler_user        => $cobbler_user,
    cobbler_password    => $cobbler_password,

    pxetimeout          => '50'
  }

  # ADDING send2syslog.py SCRIPT AND CORRESPONDING SNIPPET
  file { "/var/www/cobbler/aux/20-puppet_stdout_syslog.conf":
    ensure   => file,
    owner    => 'root',
    group    => 'root',
    source   => "puppet:///modules/nailgun/puppet-stdout.conf",
    require  => Class['::cobbler::server'],
    notify   => Class['rsyslog::service'],
  }

  file { "/var/www/cobbler/aux/20-puppet_error_syslog.conf":
    ensure   => file,
    owner    => 'root',
    group    => 'root',
    source   => "puppet:///modules/nailgun/puppet-error.conf",
    require  => Class['::cobbler::server'],
    notify   => Class['rsyslog::service'],
  }

  file { "/var/www/cobbler/aux/send2syslog.py":
    ensure => '/bin/send2syslog.py',
    require => Class["::cobbler::server"],
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
    require => Cobbler_distro["centos-x86_64"],
  }

  cobbler_profile { "ubuntu_1204_x86_64":
    kickstart => "/var/lib/cobbler/kickstarts/ubuntu-amd64.preseed",
    kopts => "netcfg/choose_interface=eth0",
    distro => "ubuntu_1204_x86_64",
    ksmeta => "",
    menu => true,
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
    kopts => "biosdevname=0 url=http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/api",
    ksmeta => "",
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

}

