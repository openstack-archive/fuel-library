class murano::dashboard (
  $enabled              = true,
  $settings_py          = '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
  $modify_config        = '/usr/bin/modify-horizon-config.sh',
  $collectstatic_script = '/usr/share/openstack-dashboard/manage.py'
) {

  include murano::params

  $dashboard_deps = $::murano::params::murano_dashboard_deps
  $package_name   = $::murano::params::murano_dashboard_package_name

  if $enabled {
    $service_ensure = 'running'
    $package_ensure = 'installed'
  } else {
    $service_ensure = 'stopped'
    $package_ensure = 'absent'
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


  exec { 'collectstatic':
    command => "${collectstatic_script} collectstatic --noinput",
  }


  package { 'murano_dashboard':
    ensure => $package_ensure,
    name   => $package_name,
  }

  package { $dashboard_deps :
    ensure => installed,
  }

  Package[$dashboard_deps] -> Package['murano_dashboard'] -> File[$modify_config] -> Exec['fix_horizon_config'] -> Exec['collectstatic'] ~> Service <| title == 'httpd' |>
  Package['murano_dashboard'] ~> Service <| title == 'httpd' |>

}
