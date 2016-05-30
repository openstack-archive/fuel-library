class nailgun::tuningbox::syncdb (
  $app_name         = $::nailgun::tuningbox::params::app_name,
  $syncdb_script    = $::nailgun::tuningbox::params::syncdb_script,
  ) inherits nailgun::tuningbox::params {

  exec {"${syncdb_script}":
    tries       => 5,
    try_sleep   => 10,
    refreshonly => true,
    path        => '/usr/bin:/bin:/usr/sbin:/sbin',
    notify      => Service["${app_name}"],
  }
}
