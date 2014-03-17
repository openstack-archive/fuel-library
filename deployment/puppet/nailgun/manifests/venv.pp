class nailgun::venv(
  $package,
  $version,
  $production,
  $nailgun_user,
  $nailgun_group,

  $database_name,
  $database_engine,
  $database_host,
  $database_port,
  $database_user,
  $database_passwd,

  $staticdir,
  $templatedir,

  $rabbitmq_naily_user,
  $rabbitmq_naily_password,

  $admin_network,
  $admin_network_cidr,
  $admin_network_size,
  $admin_network_first,
  $admin_network_last,
  $admin_network_netmask,
  $admin_network_ip,

  $exclude_network = $admin_network,
  $exclude_cidr = $admin_network_cidr,

  ) {

  file { "/etc/nailgun":
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => 0755,
  }


  $fuel_key = $::generate_fuel_key

  file { "/etc/nailgun/settings.yaml":
    content => template("nailgun/settings.yaml.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => File["/etc/nailgun"],
  }

  file { "/usr/local/bin/fuel":
    ensure  => link,
    target  => "/usr/bin/fuel",
   # require => Nailgun::Venv::Pip["${venv}_${package}"],
  }

  exec {"nailgun_syncdb":
    command => "/usr/bin/nailgun_syncdb",
    require => [
                File["/etc/nailgun/settings.yaml"],
                # Nailgun::Venv::Pip["${venv}_${package}"],
                # Nailgun::Venv::Pip["${venv}_psycopg2"],
                Class["nailgun::database"],
                ],
  }

  exec {"nailgun_upload_fixtures":
    command => "/usr/bin/nailgun_fixtures",
    require => Exec["nailgun_syncdb"],
  }

  file {"/etc/cron.daily/capacity":
    content => template("nailgun/cron_daily_capacity.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644
  }

}