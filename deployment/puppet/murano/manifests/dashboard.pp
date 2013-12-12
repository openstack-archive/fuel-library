class murano::dashboard (
  $local_settings_path = $murano::params::local_settings_path,
  $murano_url_string   = $murano::params::default_url_string,
  $dashboard_deps      = $murano::params::dashboard_deps_name,
  $package_name        = $murano::params::dashboard_package_name,
) inherits murano::params {

  file_line { 'murano_url' :
    ensure  => 'present',
    path    => $local_settings_path,
    line    => $murano_url_string,
  }

  package { 'murano_dashboard':
    ensure => present,
    name   => $package_name,
  }

  package { $dashboard_deps :
    ensure => installed,
  }

  Package[$dashboard_deps] -> Package['murano_dashboard'] ~> Service <| title == 'httpd' |>
  File <| title == $local_settings_path |> -> File_line['murano_url']

}
