class nailgun::tuningbox::syncdb (
  $app_name         = $::nailgun::tuningbox::params::app_name,
  $syncdb_script    = $::nailgun::tuningbox::params::syncdb_script,
  $env_settings_var = $::nailgun::tuningbox::params::env_settings_var,
  $config_file_path = $::nailgun::tuningbox::params::config_file_path,
  ) inherits nailgun::tuningbox::params {

  exec {"${syncdb_script}":
    tries       => 5,
    try_sleep   => 10,
    refreshonly => true,
    path        => '/usr/bin:/bin:/usr/sbin:/sbin',
    environment => ["${env_settings_var}=${config_file_path}"],
    notify      => Service["${app_name}"],
  }
}
