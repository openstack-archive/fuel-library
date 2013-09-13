class murano::dashboard (
  $enabled            = true,
  $settings_py        = '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
) {


  include murano::params

  if $enabled {
    $service_ensure = 'running'
    $line_in_settings_py__ensure = 'present'
    $package_ensure = 'installed'

  } else {
    $service_ensure = 'stopped'
    $line_in_settings_py_ensure = 'absent'
    $package_ensure = 'absent'
  }



  exec { 'fix_horizon_config':
    command     => "/usr/bin/modify-horizon-config.sh install  /usr/share/openstack-dashboard/openstack_dashboard/settings.py",
    notify      => Service['httpd'],
    require     => Package['murano_dashboard']
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
