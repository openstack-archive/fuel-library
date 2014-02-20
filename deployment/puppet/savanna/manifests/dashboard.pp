# Installs & configure the savanna API service

class savanna::dashboard (
  $enabled            = true,
  $settings_py        = $savanna::params::settings_path,
  $local_settings     = $savanna::params::local_settings_path,
  $use_neutron        = false,
  $use_floating_ips   = false,
) inherits savanna::params {

  include stdlib

  if $enabled {
    $line_ensure = 'present'
    $package_ensure = 'installed'

  } else {
    $line_ensure = 'absent'
    $package_ensure = 'absent'
  }

  # floating_ips can be enabled only if there is no neutron
  if $use_neutron {
    $use_neutron_value = 'True'
    $use_floating_ips_value = 'False'
  } else {
    if $use_floating_ips {
      $use_floating_ips_value = 'True'
    } else {
      $use_floating_ips_value = 'False'
    }
    $use_neutron_value = 'False'
  }

  File_line {
    ensure => $line_ensure,
  }

  if !defined(File[$settings_py]) {
    file { $settings_py :
      ensure  => present,
    }
  }

  file_line{ 'savanna' :
    path    => $settings_py,
    line    => "HORIZON_CONFIG['dashboards']+=('savanna',)",  # don't use .append(), target may be a tuple
    require => File[$settings_py],
  }

  file_line{ 'savanna_dashboard' :
    path    => $settings_py,
    line    => "INSTALLED_APPS+=('savannadashboard',)",  # don't use .append(), target may be a tuple
    require => File[$settings_py],
  }

  file_line{ 'savanna_use_neutron' :
    path    => $local_settings,
    line    => "SAVANNA_USE_NEUTRON=${use_neutron_value}",
  }

  file_line{ 'savanna_floating_ips' :
    path    => $local_settings,
    line    => "AUTO_ASSIGNMENT_ENABLED=${use_floating_ips_value}",
  }

  package { 'savanna_dashboard':
    ensure => $package_ensure,
    name   => $savanna::params::savanna_dashboard_package_name,
  }

  File_line <| title == 'savanna' or title == 'savanna_dashboard' |> ~> Service <| title == 'httpd' |>
  File <| title == $settings_py or title == $local_settings |> ~> Service <| title == 'httpd' |>
  Package['savanna_dashboard'] -> File <| title == $settings_py or title == $local_settings |>

}
