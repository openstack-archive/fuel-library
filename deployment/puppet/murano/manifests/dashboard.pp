class murano::dashboard (
  $settings_py                    = '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
  $modify_config                  = '/usr/bin/modify-horizon-config.sh',
#  $collect_static_script         = '/usr/share/openstack-dashboard/manage.py',
  $murano_url_string              = $::murano::params::default_url_string,
  $murano_metadata_url_string     = $::murano::params::default_metadata_url_string,
  $local_settings                 = $::murano::params::local_settings_path,
) {

  include murano::params

  $dashboard_deps = $::murano::params::murano_dashboard_deps
  $package_name   = $::murano::params::murano_dashboard_package_name

  File_line {
    ensure => 'present',
  }

  file_line{ 'murano_url' :
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

  exec { 'fix_horizon_config':
    command => "${modify_config} install ${settings_py}",
  }

  if $::osfamily == 'RedHat' {
    $apache_user = 'apache'
  } else {
    $apache_user = 'www-data'
  }

#  exec { 'collect_static':
#    command => "${collect_static_script} collectstatic --noinput",
#    user    => $apache_user,
#    group   => $apache_user,
#  }

  package { 'murano_dashboard':
    ensure => present,
    name   => $package_name,
  }

  package { $dashboard_deps :
    ensure => installed,
  }

#  Package[$dashboard_deps] -> Package['murano_dashboard'] -> File[$modify_config] -> Exec['fix_horizon_config'] -> Exec['collect_static'] -> Service <| title == 'httpd' |>
  Package[$dashboard_deps] -> Package['murano_dashboard'] -> File[$modify_config] -> Exec['fix_horizon_config'] ->  Service <| title == 'httpd' |>
  Package['murano_dashboard'] ~> Service <| title == 'httpd' |>
  Exec['fix_horizon_config'] ~> Service <| title == 'httpd' |>

}
