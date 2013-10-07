class nailgun::venv(
  $venv,
  $venv_opts = "",
  $package,
  $version,
  $pip_opts = "",

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

  nailgun::venv::venv { $venv:
    ensure => "present",
    venv => $venv,
    opts => $venv_opts,
    require => Package["python-virtualenv"],
    pip_opts => $pip_opts,
  }

  Nailgun::Venv::Pip {
    require => [
      Nailgun::Venv::Venv[$venv],
      Package["python-devel"],
      Package["gcc"],
      Package["make"],
    ],
    opts => $pip_opts,
    venv => $venv,
  }

  nailgun::venv::pip { "$venv_$package":
    package => "$package==$version",
  }

  nailgun::venv::pip { "psycopg2":
    package => "psycopg2==2.4.6",
    require => [
      Package["postgresql-devel"],
      Nailgun::Venv::Venv[$venv],
      Package["python-devel"],
      Package["gcc"],
      Package["make"],
    ],
  }

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
    target  => "/opt/nailgun/bin/fuel",
    require => Nailgun::Venv::Pip["$venv_$package"],
  }

  exec {"nailgun_syncdb":
    command => "${venv}/bin/nailgun_syncdb",
    require => [
                File["/etc/nailgun/settings.yaml"],
                Nailgun::Venv::Pip["$venv_$package"],
                Nailgun::Venv::Pip["psycopg2"],
                Class["nailgun::database"],
                ],
  }

  exec {"nailgun_upload_fixtures":
    command => "${venv}/bin/nailgun_fixtures",
    require => Exec["nailgun_syncdb"],
  }

  file {"/etc/cron.daily/capacity":
    content => template("nailgun/cron_daily_capacity.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644
  }

  }
