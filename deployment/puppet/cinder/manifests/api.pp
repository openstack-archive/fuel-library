#
class cinder::api (
  $keystone_password,
  $keystone_enabled       = true,
  $keystone_tenant        = 'services',
  $keystone_user          = 'cinder',
  $keystone_auth_host     = 'localhost',
  $keystone_auth_port     = '35357',
  $keystone_auth_protocol = 'http',
  $package_ensure         = 'latest',
  $bind_host              = '0.0.0.0',
  $enabled                = true
) {

  include cinder::params

  if ($::cinder::params::api_package) { 
    $api_package = $::cinder::params::api_package
    package { 'cinder-api':
      name   => $api_package,
      ensure => $package_ensure,
    }
  } else {
    $api_package = $::cinder::params::package_name
  }

  Cinder_config<||> ~> Service['cinder-api']
  Cinder_config<||> ~> Exec['cinder-manage db_sync']
  Cinder_api_paste_ini<||> ~> Service['cinder-api']
  Package[$api_package] -> Cinder_config<||>
  Package[$api_package] -> Cinder_api_paste_ini<||>

  if $enabled {
    $ensure = 'running'
  } else {
    $ensure = 'stopped'
  }
  case $::osfamily {
    "Debian":  {
      File[$::cinder::params::cinder_conf] -> Cinder_config<||>
      Cinder_config <| |> -> Package['cinder-api']
    }
  }
 
 #  package { 'python-keystone':
 #   ensure => $package_ensure,
 # }

  service { 'cinder-api':
    name      => $::cinder::params::api_service,
    enable    => $enabled,
    ensure    => $ensure,
    require   => Package[$api_package, 'python-keystone'],
  }
  cinder_config {
    'DEFAULT/bind_host': value => $bind_host;
    'DEFAULT/osapi_volume_listen': value => $bind_host;
  }
  if $keystone_enabled {
    cinder_config {
      'DEFAULT/auth_strategy':     value => 'keystone' ;
    }
    cinder_api_paste_ini {
      'filter:authtoken/service_port': value => 5000;
      'filter:authtoken/service_protocol': value => $keystone_auth_protocol;
      'filter:authtoken/service_host': value => $keystone_auth_host;
    }

    cinder_config {
      'keystone_authtoken/auth_protocol':     value => $keystone_auth_protocol;
      'keystone_authtoken/auth_host':         value => $keystone_auth_host;
      'keystone_authtoken/auth_port':         value => $keystone_auth_port;
      'keystone_authtoken/admin_tenant_name': value => $keystone_tenant;
      'keystone_authtoken/admin_user':        value => $keystone_user;
      'keystone_authtoken/admin_password':    value => $keystone_password;
    }
  }
 exec { 'cinder-manage db_sync':
    command     => $::cinder::params::db_sync_command,
    path        => '/usr/bin',
    user        => 'cinder',
    refreshonly => true,
    logoutput   => 'on_failure',
  }

}
