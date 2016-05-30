class nailgun::tuningbox::uwsgi(
  $port              = $::nailgun::tuningbox::params::port,
  $app_path          = $::nailgun::tuningbox::params::app_path,
  $app_module        = $::nailgun::tuningbox::params::app_module,
  $uwsgi_config_path = $::nailgun::tuningbox::params::uwsgi_config_path,
  $uwsgi_packages    = $::nailgun::tuningbox::params::uwsgi_packages,
  $config_file_path  = $::nailgun::tuningbox::params::config_file_path,
  $pid_path          = $::nailgun::tuningbox::params::pid_path,
  $log_path          = $::nailgun::tuningbox::params::log_path,
  ) inherits nailgun::tuningbox::params {

  package { "${uwsgi_packages}":
    ensure => installed,
  } ->
  file { "${uwsgi_config_path}":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('nailgun/tuningbox/uwsgi_tuningbox.yaml.erb'),
  }
}
