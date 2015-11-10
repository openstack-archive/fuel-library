class nailgun::venv(
  $venv,
  $venv_opts = "",
  $package,
  $version,
  $pip_opts = "",

  $production,
  $nailgun_user,
  $nailgun_group,

  $feature_groups,

  $database_name,
  $database_engine,
  $database_host,
  $database_port,
  $database_user,
  $database_passwd,

  $staticdir,
  $templatedir,

  $rabbitmq_host,
  $rabbitmq_astute_user,
  $rabbitmq_astute_password,

  $nailgun_log_level = "DEBUG",

  $admin_network,
  $admin_network_cidr,
  $admin_network_size,
  $admin_network_first,
  $admin_network_last,
  $admin_network_netmask,
  $admin_network_mac,
  $admin_network_ip,
  $admin_network_gateway,

  $cobbler_host,
  $cobbler_url,
  $cobbler_user = "cobbler",
  $cobbler_password = "cobbler",

  $mco_pskey,
  $mco_vhost,
  $mco_host,
  $mco_user,
  $mco_password,
  $mco_connector,

  $puppet_master_hostname,

  $exclude_network = $admin_network,
  $exclude_cidr = $admin_network_cidr,

  $keystone_host = '127.0.0.1',
  $keystone_nailgun_user = 'nailgun',
  $keystone_nailgun_pass = 'nailgun',

  $dns_domain,
  $dns_upstream = '8.8.8.8, 8.8.4.4',
  $ntp_upstream = '0.pool.ntp.org, 1.pool.ntp.org',
  ) {

  package{'fuel-nailgun':}

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
  }

  case $production {
    'docker': {
      exec {"nailgun_syncdb":
        command   => "${venv}/bin/nailgun_syncdb",
        require   => [
                    File["/etc/nailgun/settings.yaml"],
                    ],
        tries     => 50,
        try_sleep => 5,
      }
      exec {"nailgun_upload_fixtures":
        command   => "${venv}/bin/nailgun_fixtures",
        require   => Exec["nailgun_syncdb"],
        tries     => 50,
        try_sleep => 5,
      }
    }
    'prod': {
      exec {"nailgun_syncdb":
        command => "${venv}/bin/nailgun_syncdb",
        require => [
                    File["/etc/nailgun/settings.yaml"],
                    Class["nailgun::database"],
                    ],
      }
      exec {"nailgun_upload_fixtures":
        command => "${venv}/bin/nailgun_fixtures",
        require => Exec["nailgun_syncdb"],
      }

    }
  }
  package {'cronie-anacron': }
  file {"/etc/cron.daily/capacity":
    content => template("nailgun/cron_daily_capacity.erb"),
    owner => 'root',
    group => 'root',
    mode  => '0644',
    require => Package['cronie-anacron']
  }

}
