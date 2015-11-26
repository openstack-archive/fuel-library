class nailgun::bootstrap_cli(
  $settings,
  $direct_repo_addresses,
  $bootstrap_cli_package,
  $sample_config_path,
  ) {

  package { $bootstrap_cli_package:
      ensure => present,
  }

  $settings['direct_repo_addresses'] = $direct_repo_addresses

  file { "/etc/fuel-agent/fuel_bootstrap_cli.yaml":
    content => template("nailgun/bootstrap_cli_settings.yaml.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    require => Package[$bootstrap_cli_package],
  }
}
