# == Class: murano::dashboard
#
#  murano dashboard package
#
# === Parameters
#
# [*package_ensure*]
#  (Optional) Ensure state for package
#  Defaults to 'present'
#
# [*api_url*]
#  (Optional) API url for murano-dashboard
#  Defaults to 'http://127.0.0.1:8082'
#
# [*repo_url*]
#  (Optional) Application repository URL for murano-dashboard
#  Defaults to 'http://storage.apps.openstack.org'
#
# [*settings_py*]
#  (Optional) Path to horizon settings
#  Defaults to '/usr/share/openstack-dashboard/openstack_dashboard/settings.py'
#
# [*modify_config*]
#  (Optional) Path to modify-horizon-config script
#  Defaults to '/usr/bin/modify-horizon-config.sh'
#
# [*collect_static_script*]
#  (Optional) Path to horizon manage utility
#  Defaults to '/usr/share/openstack-dashboard/manage.py'
#
class murano::dashboard(
  $package_ensure        = 'present',
  $api_url               = 'http://127.0.0.1:8082',
  $repo_url              = 'http://storage.apps.openstack.org',
  $settings_py           = '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
  $modify_config         = '/usr/bin/modify-horizon-config.sh',
  $collect_static_script = '/usr/share/openstack-dashboard/manage.py',
) {

  include ::murano::params

  $apache_user = $::osfamily ? {
    'RedHat' => 'apache',
    'Debian' => 'horizon',
    default  => 'www-data',
  }

  package { 'murano-dashboard':
    ensure => $package_ensure,
    name   => $::murano::params::dashboard_package_name,
  }

  File_line {
    ensure => 'present',
  }

  file_line { 'murano_url' :
    path => $::murano::params::local_settings_path,
    line => "MURANO_API_URL = '${api_url}'",
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
      'MURANO_SSL_ENABLED=False',
      "MURANO_REPO_URL=${repo_url}",
      'USE_KEYSTONE_ENDPOINT=True',
      'USE_SQLITE_BACKEND=False',
      "APACHE_USER=${apache_user}",
      "APACHE_GROUP=${apache_user}",
    ],
  }

  exec { 'django_collectstatic':
    command     => "${collect_static_script} collectstatic --noinput",
    environment => [
      "APACHE_USER=${apache_user}",
      "APACHE_GROUP=${apache_user}",
    ],
  }

  Package['murano-dashboard'] -> File[$modify_config] -> Exec['clean_horizon_config'] -> Exec['fix_horizon_config'] -> Exec['django_collectstatic'] -> Service <| title == 'httpd' |>
  Package['murano-dashboard'] ~> Service <| title == 'httpd' |>
  Exec['fix_horizon_config'] ~> Service <| title == 'httpd' |>
}
