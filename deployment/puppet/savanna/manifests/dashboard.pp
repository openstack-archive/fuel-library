# Installs & configure the savanna API service

class savanna::dashboard (
  $enabled            = true,
  $settings_py        = '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
  $local_settings     = '/etc/openstack-dashboard/local_settings',
  $savanna_url_string = "SAVANNA_URL = 'http://localhost:8386/v1.0'"
) {

  include savanna::params
  include stdlib

  if $enabled {
    $line_ensure = 'present'
    $package_ensure = 'installed'

  } else {
    $line_ensure = 'absent'
    $package_ensure = 'absent'
  }

  File_line {
    ensure => $line_ensure,
  }

  if !defined(File[$settings_py]) {
    file { $settings_py :
      ensure  => present,
    }
  }

  file_line{'savanna' :
    path    => $settings_py,
    line    => "HORIZON_CONFIG['dashboards'].append('savanna')",
    require => File[$settings_py],
  }

  file_line{'savanna_dashboard' :
    path    => $settings_py,
    line    => "INSTALLED_APPS.append('savannadashboard')",
    require => File[$settings_py],
  }

  file_line{'savanna_url' :
    path    => $local_settings,
    line    => $savanna_url_string,
    require => File[$local_settings],
  }

  package { 'savanna_dashboard':
    ensure => $package_ensure,
    name   => $::savanna::params::savanna_dashboard_package_name,
  }

  File_line <| title == 'savanna' or title == 'savanna_dashboard' or title == 'savanna_url' |> ~> Service <| title == 'httpd' |>
  File <| title == $settings_py or title == $local_settings |> ~> Service <| title == 'httpd' |>
  Package['savanna_dashboard'] -> File <| title == $settings_py or title == $local_settings |>

}
