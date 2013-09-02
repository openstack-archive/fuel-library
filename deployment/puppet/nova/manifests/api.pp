#
# installs and configures nova api service
#
# * admin_password
# * enabled
# * ensure_package
# * auth_strategy
# * auth_host
# * auth_port
# * auth_protocol
# * admin_tenant_name
# * admin_user
# * enabled_apis
#
class nova::api(
  $admin_password,
  $enabled           = false,
  $ensure_package    = 'present',
  $auth_strategy     = 'keystone',
  $auth_host         = '127.0.0.1',
  $auth_port         = 35357,
  $auth_protocol     = 'http',
  $admin_tenant_name = 'services',
  $admin_user        = 'nova',
  $cinder            = true,
  $enabled_apis      = 'ec2,osapi_compute,metadata',
  $nova_rate_limits  = undef,
  $nova_user_password= undef, #Empty password generates error and saves from non-working installation
) {

  include nova::params

  if !defined(Package[$::nova::params::pymemcache_package_name]) {
    package { $::nova::params::pymemcache_package_name:
      ensure => present,
      before => Nova::Generic_service['api'],
    }
  }

  Package<| title == 'nova-api' |> -> Exec['nova-db-sync']
  case $::osfamily {
    "Debian": {
        Nova_config<| |> -> Package<| title == 'nova-api' |>
        Nova_paste_api_ini<| |> -> Package<| title == 'nova-api' |>
    }
    "RedHat": {
        Package<| title == 'nova-api' |> -> Nova_config<| |>
    }
  }
  
  Package<| title == 'nova-common' |> -> Nova_paste_api_ini<| |>
  Nova_paste_api_ini<| |> ~> Exec['post-nova_config']
  Nova_paste_api_ini<| |> ~> Service['nova-api']
  

  nova_paste_api_ini {
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
      'filter:authtoken/signing_dirname': ensure => absent;
  } 
    
  if $nova_rate_limits {
      class{'::nova::limits': limits => $nova_rate_limits}
  }

  Nova_config<| |> ~> Exec['post-nova_config']
  Nova_config<| |> ~> Service['nova-api']

  nova::generic_service { 'api':
    enabled        => $enabled,
    ensure_package => $ensure_package,
    package_name   => $::nova::params::api_package_name,
    service_name   => $::nova::params::api_service_name,
  }
  
  if $cinder {
    $volume_api_class = 'nova.volume.cinder.API'
  } else {
    $volume_api_class = 'nova.volume.api.API'
  }

  nova_config {
    'DEFAULT/api_paste_config': value => '/etc/nova/api-paste.ini';
    'DEFAULT/enabled_apis':     value => $enabled_apis;
    'DEFAULT/volume_api_class': value => $volume_api_class;
    'DEFAULT/keystone_ec2_url': value => "http://${auth_host}:5000/v2.0/ec2tokens";
  }
  nova_config {
    'keystone_authtoken/auth_host':         value => $auth_host;
    'keystone_authtoken/auth_port':         value => $auth_port;
    'keystone_authtoken/auth_protocol':     value => $auth_protocol;
    'keystone_authtoken/admin_tenant_name': value => $admin_tenant_name;
    'keystone_authtoken/admin_user':        value => $admin_user;
    'keystone_authtoken/admin_password':    value => $admin_password;
    'keystone_authtoken/signing_dir':       value => '/tmp/keystone-signing-nova';
    'keystone_authtoken/signing_dirname':   value => '/tmp/keystone-signing-nova';
  }

  # I need to ensure that I better understand this resource
  # this is potentially constantly resyncing a central DB
  exec { "nova-db-sync":
    command      => "/usr/bin/nova-manage db sync",
   #refreshonly  => "true",
    subscribe    => Exec['post-nova_config'],
   #user         => User[nova],
    logoutput    => true,
  }
 
}
