class nova::api(
  $enabled           = false,
  $ensure_package    = 'present',
  $auth_strategy     = 'keystone',
  $auth_host         = '127.0.0.1',
  $auth_port         = 35357,
  $auth_protocol     = 'http',
  $admin_tenant_name = 'services',
  $admin_user        = 'nova',
  $admin_password    = 'passw0rd'
) {

  include nova::params

  Package<| title == 'nova-api' |> -> Exec['nova-db-sync']
  Package<| title == 'nova-api' |> -> Nova_paste_api_ini<| |>

  Nova_paste_api_ini<| |> ~> Exec['post-nova_config']
  Nova_paste_api_ini<| |> ~> Service['nova-api']

  nova::generic_service { 'api':
    enabled        => $enabled,
    ensure_package => $ensure_package,
    package_name   => $::nova::params::api_package_name,
    service_name   => $::nova::params::api_service_name,
  }

  nova_config { 'api_paste_config': value => '/etc/nova/api-paste.ini'; }

  nova_paste_api_ini {
    'filter:authtoken/auth_host':         value => $auth_host;
    'filter:authtoken/auth_port':         value => $auth_port;
    'filter:authtoken/auth_protocol':     value => $auth_protocol;
    'filter:authtoken/admin_tenant_name': value => $admin_tenant_name;
    'filter:authtoken/admin_user':        value => $admin_user;
    'filter:authtoken/admin_password':    value => $admin_password;
  }

  # I need to ensure that I better understand this resource
  # this is potentially constantly resyncing a central DB
  exec { "nova-db-sync":
    command     => "/usr/bin/nova-manage db sync",
    refreshonly => "true",
    subscribe   => Exec['post-nova_config'],
  }

}
