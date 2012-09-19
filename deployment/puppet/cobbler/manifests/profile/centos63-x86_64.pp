class cobbler::profile::centos63-x86_64(
  $kickstart_name              = "centos63-x86_64.ks",
  $distro                      = "centos63-x86_64",
  $kopts                       = "",

  # kickstart variables
  $kickstart_repo_url          = "http://mirror.stanford.edu/yum/pub/centos/6.3/os/x86_64",
  $kickstart_puppet_repo_url   = "http://yum.puppetlabs.com/el/6/products/x86_64",
  $kickstart_system_timezone   = "America/Los_Angeles",

  # default password is 'r00tme'
  $kickstart_encrypted_root_password = "\$6\$tCD3X7ji\$1urw6qEMDkVxOkD33b4TpQAjRiCeDZx0jmgMhDYhfB9KuGfqO9OcMaKyUxnGGWslEDQ4HxTw7vcAMP85NxQe61",
  ) {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  
  
  case $operatingsystem {
    /(?i)(ubuntu|debian|centos|redhat)$/:  {
      $kickstart_dir = "/var/lib/cobbler/kickstarts"
    }
  }
  
  file { "${kickstart_dir}/${kickstart_name}":
    content => template("cobbler/centos63-x86_64.ks.erb"),
    owner => root,
    group => root,
    mode => 0644,
  }

  cobbler_profile { "centos63-x86_64":
    kickstart => "${kickstart_dir}/${kickstart_name}",
    kopts => $kopts,
    distro => $distro,
    ksmeta => "",
    menu => true,
  }
  
}

