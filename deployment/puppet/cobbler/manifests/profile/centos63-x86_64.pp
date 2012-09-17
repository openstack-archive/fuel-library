class cobbler::profile::centos63-x86_64(
  $kickstart_name              = "centos63-x86_64.ks",
  $kickstart_partition_snippet = "partition_default",
  $kickstart_network_snippet   = "network_default",
  $distro                      = "centos63-x86_64",
  $kopts                       = ""
  ) {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  case $operatingsystem {
    /(?i)(ubuntu|centos|redhat)$/:  {
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
    menu => true,
  }
  
}

