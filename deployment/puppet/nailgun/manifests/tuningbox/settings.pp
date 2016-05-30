class nailgun::tuningbox::settings (
  $keystone_host       = $::nailgun::tuningbox::params::keystone_host,
  $keystone_user       = $::nailgun::tuningbox::params::keystone_user,
  $keystone_pass       = $::nailgun::tuningbox::params::keystone_pass,
  $tenant              = $::nailgun::tuningbox::params::keystone_tenant,
  $database_connection = $::nailgun::tuningbox::params::db_connection,
  $package_name        = $::nailgun::tuningbox::params::package_name,
  $config_folder       = $::nailgun::tuningbox::params::config_folder,
  $config_file_path    = $::nailgun::tuningbox::params::config_file_path,
  $tuningbox_log_level = $::nailgun::tuningbox::params::tuningbox_log_level,
  $log_dir             = $::nailgun::tuningbox::params::log_dir,
  $ssl_keys_dir        = $::nailgun::tuningbox::params::ssl_keys_dir,
  $dns_domain          = $::nailgun::tuningbox::params::dns_domain,
  $app_name            = $::nailgun::tuningbox::params::app_name,
  ) inherits nailgun::tuningbox::params {

  file { "${log_dir}":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  package { "${package_name}":
    ensure => installed,
  }

  file { "${config_folder}":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { "${ssl_keys_dir}":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${config_folder}"],
  }

  openssl::certificate::x509 { "${app_name}":
    ensure       => present,
    country      => 'US',
    organization => 'Fuel',
    commonname   => $::fqdn,
    state        => 'California',
    unit         => 'Fuel Deployment Team',
    email        => "root@${dns_domain}",
    days         => 3650,
    base_dir     => "${ssl_keys_dir}",
    owner        => 'root',
    group        => 'root',
    force        => false,
    cnf_tpl      => 'openssl/cert.cnf.erb',
    require      => File["${ssl_keys_dir}"],
  }

  file { "${config_file_path}":
    content => template('nailgun/tuningbox/tuningbox_config.py.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File["${config_folder}"],
  }
}
