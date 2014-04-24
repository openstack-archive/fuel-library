class docker::dockerctl (
  $bin_dir    = '/usr/bin',
  $share_dir  = '/usr/share/dockerctl',
  $config_dir = '/etc/dockerctl',
  $release,
  $production,
) {

  # Make sure we have needed directories
  file { "$bin_dir":
    ensure => directory;
  }
  file { "$share_dir":
    ensure => directory;
  }
  file { "$config_dir":
    ensure => directory;
  }

  # Deploy files
  file { "$bin_dir/dockerctl":
    require => File["$bin_dir"],
    mode    => 0755,
    content => template("docker/dockerctl.erb");
  }
  file { "$bin_dir/disable-services.sh":
    require => File["$bin_dir"],
    mode    => 0755,
    content => template("docker/disable-services.sh.erb");
  }
  file { "$share_dir/functions":
    require => File["$share_dir"],
    mode    => 0644,
    content => template("docker/functions.sh.erb");
  }
  file { "$config_dir/config":
    require => File["$config_dir"],
    mode    => 0644,
    content => template("docker/dockerctl_config.erb");
  }
}
