class murano::dashboard (
  $settings_py                    = '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
  $modify_config                  = '/usr/bin/modify-horizon-config.sh',
  $collect_static_script          = '/usr/share/openstack-dashboard/manage.py',
  $murano_log_file                = '/var/log/murano/murano-dashboard.log',
  $murano_url_string              = $::murano::params::default_url_string,
  $local_settings                 = $::murano::params::local_settings_path,
) {

  include murano::params

  $package_name = $::murano::params::murano_dashboard_package_name

  $apache_user = $::osfamily ? {
    'RedHat' => 'apache',
    'Debian' => 'horizon',
    default  => 'www-data',
  }

  File_line {
    ensure => 'present',
  }

  file_line { 'murano_url' :
    path    => $local_settings,
    line    => $murano_url_string,
    require => File[$local_settings],
  }

  file { $modify_config :
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  exec { 'clean_horizon_config':
    command => "${modify_config} uninstall",
  }

  exec { 'fix_horizon_config':
    command     => "${modify_config} install",
    environment => [
      "HORIZON_CONFIG=${settings_py}",
      "MURANO_SSL_ENABLED=False",
      "USE_KEYSTONE_ENDPOINT=True",
      "USE_SQLITE_BACKEND=False",
      "APACHE_USER=${apache_user}",
      "APACHE_GROUP=${apache_user}",
    ],
  }

  file { $murano_log_file :
    ensure => present,
    mode   => '0755',
    owner  => $apache_user,
    group  => 'root',
  }

  package { 'murano_dashboard':
    ensure => present,
    name   => $package_name,
  }

  Package['murano_dashboard'] -> File[$modify_config] -> Exec['clean_horizon_config'] -> Exec['fix_horizon_config'] -> File[$murano_log_file] -> File <| title == "${::horizon::params::logdir}/horizon.log" |> -> Service <| title == 'httpd' |>
  Package['murano_dashboard'] ~> Service <| title == 'httpd' |>
  Exec['fix_horizon_config'] ~> Service <| title == 'httpd' |>

}
