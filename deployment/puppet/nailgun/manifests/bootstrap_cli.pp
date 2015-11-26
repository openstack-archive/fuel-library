class nailgun::bootstrap_cli(
  $settings,
  $admin_ipaddress,
  $bootstrap_cli_package,
  $sample_config_path,
  ) {

  $settings_hash = { 'BOOTSTRAP' => $settings }

  package { $bootstrap_cli_package:
      ensure => present,
  }

  file { "/etc/fuel-agent/fuel_bootstrap_cli.yaml":
    content => template("nailgun/bootstrap_cli_settings.yaml.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    require => Package[$bootstrap_cli_package],
  }
}
