class docker::dockerctl (
  $bin_dir         = '/usr/bin',
  $share_dir       = '/usr/share/dockerctl',
  $config_dir      = '/etc/dockerctl',
  $profile_dir     = '/etc/profile.d',
  $admin_ipaddress = $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  $docker_engine   = 'native',
  $use_systemd     = false,
  $release,
  $production,
) {

  # Make sure we have needed directories
  #  file { [$bin_dir, $share_dir, $config_dir, $profile_dir]:
  #  ensure => directory;
  #}

  # Deploy files
  # file { "$bin_dir/dockerctl":
  #  mode    => 0755,
  #  content => template("docker/dockerctl.erb");
  #}

  # file { "$profile_dir/dockerctl.sh":
  #  content => template("docker/dockerctl-alias.sh.erb"),
  #  owner   => 'root',
  #  group   => 'root',
  #  mode    => '0755',
  #}
  #file { "$bin_dir/get_service_credentials.py":
  #  mode    => 0755,
  #  content => template("docker/get_service_credentials.py.erb")
  #}
  #file { "$share_dir/functions.sh":
  #  mode    => 0644,
  #  content => template("docker/functions.sh.erb")
  #}
  file { "${config_dir}/config":
    mode    => '0644',
    content => template('docker/dockerctl_config.erb')
  }
}
