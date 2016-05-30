class nailgun::tuningbox::uwsgi(
  $http_port         = $::nailgun::tuningbox::params::http_port,
  $https_port        = $::nailgun::tuningbox::params::https_port,
  $app_name          = $::nailgun::tuningbox::params::app_name,
  $app_path          = $::nailgun::tuningbox::params::app_path,
  $app_module        = $::nailgun::tuningbox::params::app_module,
  $uwsgi_config_path = $::nailgun::tuningbox::params::uwsgi_config_path,
  $uwsgi_packages    = $::nailgun::tuningbox::params::uwsgi_packages,
  $config_file_path  = $::nailgun::tuningbox::params::config_file_path,
  $pid_path          = $::nailgun::tuningbox::params::pid_path,
  $log_path          = $::nailgun::tuningbox::params::log_path,
  $env_settings_var  = $::nailgun::tuningbox::params::env_settings_var,
  $ssl_keys_dir      = $::nailgun::tuningbox::params::ssl_keys_dir,
  ) inherits nailgun::tuningbox::params {

  firewall { '200 tuning_box http api':
    chain  => 'INPUT',
    port   => $http_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '201 tuning_box https api':
    chain  => 'INPUT',
    port   => $https_port,
    proto  => 'tcp',
    action => 'accept',
  }

  package { $uwsgi_packages:
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
