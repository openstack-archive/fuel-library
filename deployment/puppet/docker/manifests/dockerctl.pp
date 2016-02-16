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

  file { "${config_dir}/config":
    mode    => '0644',
    content => template('docker/dockerctl_config.erb')
  }
}
