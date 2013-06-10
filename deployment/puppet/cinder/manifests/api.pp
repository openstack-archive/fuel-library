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
  $enabled                = true,
  $cinder_rate_limits = undef
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
if $cinder_rate_limits {
  class{'::cinder::limits': limits => $cinder_rate_limits}
}
  Cinder_config<||> ~> Service['cinder-api']
  Cinder_config<||> ~> Exec['cinder-manage db_sync']
  Cinder_api_paste_ini<||> ~> Service['cinder-api']

  if $enabled {
    $ensure = 'running'
  } else {
    $ensure = 'stopped'
  }
  case $::osfamily {
    "Debian":  {
      File[$::cinder::params::cinder_conf] -> Cinder_config<||>
      File[$::cinder::params::cinder_paste_api_ini] -> Cinder_api_paste_ini<||>
      Cinder_config <| |> -> Package['cinder-api']
      Cinder_api_paste_ini<||> -> Package['cinder-api']
    }
    "RedHat": {
  Package[$api_package] -> Cinder_api_paste_ini<||>
  Package[$api_package] -> Cinder_config<||>
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
     cinder_api_paste_ini {
      'filter:authtoken/service_port': ensure => absent;
      'filter:authtoken/service_protocol': ensure => absent;
      'filter:authtoken/service_host': ensure => absent;
      'filter:authtoken/auth_port': ensure => absent;
      'filter:authtoken/auth_protocol': ensure => absent;
      'filter:authtoken/auth_host': ensure => absent;
      'filter:authtoken/admin_tenant_name': ensure => absent;
      'filter:authtoken/admin_user': ensure => absent;
      'filter:authtoken/admin_password': ensure => absent;
      'filter:authtoken/signing_dir': ensure => absent;
    }

 if $keystone_enabled {
    cinder_config {
      'keystone_authtoken/auth_protocol':     value => $keystone_auth_protocol;
      'keystone_authtoken/auth_host':         value => $keystone_auth_host;
      'keystone_authtoken/auth_port':         value => $keystone_auth_port;
      'keystone_authtoken/admin_tenant_name': value => $keystone_tenant;
      'keystone_authtoken/admin_user':        value => $keystone_user;
      'keystone_authtoken/admin_password':    value => $keystone_password;
      'keystone_authtoken/signing_dir':       value => '/tmp/keystone-signing-cinder';
      'keystone_authtoken/signing_dirname':   value => '/tmp/keystone-signing-cinder';
    }
  }
}
