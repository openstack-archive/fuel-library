class cobbler::profile::centos63-x86_64(
  $distro             = "centos63-x86_64",
  $ks_puppet_repo     = "http://yum.puppetlabs.com/el/6/products/x86_64",
  $ks_system_timezone = "America/Los_Angeles",

  # default password is 'r00tme'
  $ks_encrypted_root_password = "\$6\$tCD3X7ji\$1urw6qEMDkVxOkD33b4TpQAjRiCeDZx0jmgMhDYhfB9KuGfqO9OcMaKyUxnGGWslEDQ4HxTw7vcAMP85NxQe61",
  ) {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  case $operatingsystem {
    /(?i)(ubuntu|debian|centos|redhat)$/:  {
      $ks_dir = "/var/lib/cobbler/kickstarts"
    }
  }
  
  file { "${ks_dir}/centos63-x86_64.ks":
    content => template("cobbler/centos.ks.erb"),
    owner => root,
    group => root,
    mode => 0644,
  }

  cobbler_profile { "centos63-x86_64":
    kickstart => "${ks_dir}/centos63-x86_64.ks",
    kopts => $kopts,
    distro => $distro,
    ksmeta => "",
    menu => true,
  }
  
}

