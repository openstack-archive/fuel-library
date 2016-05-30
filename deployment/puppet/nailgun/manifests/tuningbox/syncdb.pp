class nailgun::tuningbox::syncdb (
  $syncdb_script    = $::nailgun::tuningbox::params::syncdb_script,
  ) inherits nailgun::tuningbox::params {

  exec {"${syncdb_script}":
    tries       => 5,
    try_sleep   => 10,
    path        => '/usr/bin:/bin:/usr/sbin:/sbin',
  }
}
