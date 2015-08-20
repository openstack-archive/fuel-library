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
# [*metadata_dir*]
#  (Optional) Directory to store murano dashboard metadata cache
#  Defaults to '/var/cache/muranodashboard-cache'
#
# [*max_file_size*]
#  (Optional) Maximum allowed filesize to upload
#  Defaults to '5'
#
class murano::dashboard(
  $package_ensure        = 'present',
  $api_url               = 'http://127.0.0.1:8082',
  $repo_url              = 'http://storage.apps.openstack.org',
  $settings_py           = '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
  $modify_config         = '/usr/bin/modify-horizon-config.sh',
  $collect_static_script = '/usr/share/openstack-dashboard/manage.py',
  $metadata_dir          = '/var/cache/muranodashboard-cache',
  $max_file_size         = '5',
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
    tag  => 'patch-horizon-config',
  }

  file_line { 'murano_repo_url':
    path => $::murano::params::local_settings_path,
    line => "MURANO_REPO_URL = '${repo_url}'",
    tag  => 'patch-horizon-config',
  }

  file_line { 'murano_max_file_size':
    path => $::murano::params::local_settings_path,
    line => "MAX_FILE_SIZE_MB = '${max_file_size}'",
    tag  => 'patch-horizon-config',
  }

  file_line { 'murano_metadata_dir':
    path => $::murano::params::local_settings_path,
    line => "METADATA_CACHE_DIR = '${metadata_dir}'",
    tag  => 'patch-horizon-config',
  }

  file_line { 'murano_dashboard_logging':
    path => $::murano::params::local_settings_path,
    line => "LOGGING['loggers']['muranodashboard'] = {'handlers': ['syslog'], 'level': 'DEBUG'}",
    tag  => 'patch-horizon-config',
  }

  file_line { 'murano_client_logging':
    path => $::murano::params::local_settings_path,
    line => "LOGGING['loggers']['muranoclient'] = {'handlers': ['syslog'], 'level': 'ERROR'}",
    tag  => 'patch-horizon-config',
  }

  exec { 'clean_horizon_config':
    command => "${modify_config} uninstall",
    onlyif  => [
      "test -f ${modify_config}",
      "grep MURANO_CONFIG_SECTION_BEGIN ${settings_py}",
    ],
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
  }

  exec { 'django_collectstatic':
    command     => "${collect_static_script} collectstatic --noinput",
    environment => [
      "APACHE_USER=${apache_user}",
      "APACHE_GROUP=${apache_user}",
    ],
    refreshonly => true,
  }

  File_line <| tag == 'patch-horizon-config' |> -> Service <| title == 'httpd' |>

  Package['murano-dashboard'] ->
    Exec['clean_horizon_config'] ->
      Service <| title == 'httpd' |>

  Package['murano-dashboard'] ~>
    Exec['django_collectstatic'] ~>
      Service <| title == 'httpd' |>
}
