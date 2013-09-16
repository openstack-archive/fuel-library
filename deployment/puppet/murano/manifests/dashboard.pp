class murano::dashboard (
  $enabled            = true,
  $settings_py        = '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
) {


  include murano::params

  Package['murano_dashboard'] -> Exec['fix_horizon_config']  ~> Service['httpd']

  if $enabled {
    $service_ensure = 'running'
    $package_ensure = 'installed'

  } else {
    $service_ensure = 'stopped'
    $package_ensure = 'absent'
  }


  exec { 'fix_horizon_config':
    command     => "/usr/bin/modify-horizon-config.sh install  /usr/share/openstack-dashboard/openstack_dashboard/settings.py",
    notify      => Service['httpd'],
}
  package { 'murano_dashboard':
    ensure => $package_ensure,
    name   => $::murano::params::murano_dashboard_package_name,
    notify => Service['httpd'],
  }


  service { 'httpd':
    ensure     => running,
    name       => httpd,
    enable     => $enabled,
  }


}
