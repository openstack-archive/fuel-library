# Installs & configure the sahara API service

class sahara::dashboard (
  $enabled            = true,
  $settings_py        = $sahara::params::settings_path,
  $local_settings     = $sahara::params::local_settings_path,
  $use_neutron        = false,
  $use_floating_ips   = false,
) inherits sahara::params {

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

  file_line{ 'sahara' :
    path    => $settings_py,
    line    => "HORIZON_CONFIG['dashboards']+=('sahara',)",  # don't use .append(), target may be a tuple
    require => File[$settings_py],
  }

  file_line{ 'sahara_dashboard' :
    path    => $settings_py,
    line    => "INSTALLED_APPS+=('saharadashboard',)",  # don't use .append(), target may be a tuple
    require => File[$settings_py],
  }

  file_line{ 'sahara_use_neutron' :
    path    => $local_settings,
    line    => "SAHARA_USE_NEUTRON=${use_neutron_value}",
  }

  file_line{ 'sahara_floating_ips' :
    path    => $local_settings,
    line    => "AUTO_ASSIGNMENT_ENABLED=${use_floating_ips_value}",
  }

  package { 'sahara_dashboard':
    ensure => $package_ensure,
    name   => $sahara::params::sahara_dashboard_package_name,
  }

  File_line <| title == 'sahara' or title == 'sahara_dashboard' |> ~> Service <| title == 'httpd' |>
  File <| title == $settings_py or title == $local_settings |> ~> Service <| title == 'httpd' |>
  Package['sahara_dashboard'] -> File <| title == $settings_py or title == $local_settings |>
}
