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
# * auth_admin_prefix: path part of the auth url. Optional.
#     This allow admin auth URIs like http://auth_host:35357/keystone/admin.
#     (where '/keystone' is the admin prefix)
#     Defaults to false for empty. If defined, should be a string with a leading '/' and no trailing '/'.
# * admin_tenant_name
# * admin_user
# * enabled_apis
# * use_forwarded_for:
#     Treat X-Forwarded-For as the canonical remote address. Only
#     enable this if you have a sanitizing proxy. (boolean value)
#     (Optional). Defaults to false.
# * neutron_metadata_proxy_shared_secret
# * ratelimit
# * ratelimit_factory
#
class nova::api(
  $admin_password,
  $enabled           = false,
  $ensure_package    = 'present',
  $auth_strategy     = undef,
  $auth_host         = '127.0.0.1',
  $auth_port         = 35357,
  $auth_protocol     = 'http',
  $auth_uri          = false,
  $auth_admin_prefix = false,
  $admin_tenant_name = 'services',
  $admin_user        = 'nova',
  $api_bind_address  = '0.0.0.0',
  $metadata_listen   = '0.0.0.0',
  $enabled_apis      = 'ec2,osapi_compute,metadata',
  $volume_api_class  = 'nova.volume.cinder.API',
  $use_forwarded_for = false,
  $workers           = $::processorcount,
  $sync_db           = true,
  $neutron_metadata_proxy_shared_secret = undef,
  $ratelimits        = undef,
  $ratelimits_factory =
    'nova.api.openstack.compute.limits:RateLimitingMiddleware.factory'
) {

  include nova::params
  require keystone::python
  include cinder::client

  Package<| title == 'nova-api' |> -> Nova_paste_api_ini<| |>

  Package<| title == 'nova-common' |> -> Class['nova::api']

  Nova_paste_api_ini<| |> ~> Exec['post-nova_config']
  Nova_paste_api_ini<| |> ~> Service['nova-api']

  if $auth_strategy {
    warning('Parameter auth_strategy is not used in class nova::api and going to be deprecated.')
  }

  nova::generic_service { 'api':
    enabled        => $enabled,
    ensure_package => $ensure_package,
    package_name   => $::nova::params::api_package_name,
    service_name   => $::nova::params::api_service_name,
    subscribe      => Class['cinder::client'],
  }

  nova_config {
    'DEFAULT/enabled_apis':          value => $enabled_apis;
    'DEFAULT/volume_api_class':      value => $volume_api_class;
    'DEFAULT/ec2_listen':            value => $api_bind_address;
    'DEFAULT/osapi_compute_listen':  value => $api_bind_address;
    'DEFAULT/metadata_listen':       value => $metadata_listen;
    'DEFAULT/osapi_volume_listen':   value => $api_bind_address;
    'DEFAULT/osapi_compute_workers': value => $workers;
    'DEFAULT/use_forwarded_for':     value => $use_forwarded_for;
  }

  if ($neutron_metadata_proxy_shared_secret){
    nova_config {
      'DEFAULT/service_neutron_metadata_proxy': value => true;
      'DEFAULT/neutron_metadata_proxy_shared_secret':
        value => $neutron_metadata_proxy_shared_secret;
    }
  } else {
    nova_config {
      'DEFAULT/service_neutron_metadata_proxy':       value  => false;
      'DEFAULT/neutron_metadata_proxy_shared_secret': ensure => absent;
    }
  }

  if $auth_uri {
    nova_config { 'keystone_authtoken/auth_uri': value => $auth_uri; }
  } else {
    nova_config { 'keystone_authtoken/auth_uri': value => "${auth_protocol}://${auth_host}:5000/"; }
  }

  nova_config {
    'keystone_authtoken/auth_host':         value => $auth_host;
    'keystone_authtoken/auth_port':         value => $auth_port;
    'keystone_authtoken/auth_protocol':     value => $auth_protocol;
    'keystone_authtoken/admin_tenant_name': value => $admin_tenant_name;
    'keystone_authtoken/admin_user':        value => $admin_user;
    'keystone_authtoken/admin_password':    value => $admin_password, secret => true;
  }

  if $auth_admin_prefix {
    validate_re($auth_admin_prefix, '^(/.+[^/])?$')
    nova_config {
      'keystone_authtoken/auth_admin_prefix': value => $auth_admin_prefix;
    }
  } else {
    nova_config {
      'keystone_authtoken/auth_admin_prefix': ensure => absent;
    }
  }

  if 'occiapi' in $enabled_apis {
    if !defined(Package['python-pip']) {
      package { 'python-pip':
        ensure => latest,
      }
    }
    if !defined(Package['pyssf']) {
      package { 'pyssf':
        ensure   => latest,
        provider => pip,
        require  => Package['python-pip']
      }
    }
    package { 'openstackocci':
      ensure   => latest,
      provider => 'pip',
      require  => Package['python-pip'],
    }
  }

  if ($ratelimits != undef) {
    nova_paste_api_ini {
      'filter:ratelimit/paste.filter_factory': value => $ratelimits_factory;
      'filter:ratelimit/limits':               value => $ratelimits;
    }
  }

  # Added arg and if statement prevents this from being run
  # where db is not active i.e. the compute
  if $sync_db {
    Package<| title == 'nova-api' |> -> Exec['nova-db-sync']
    exec { 'nova-db-sync':
      command     => '/usr/bin/nova-manage db sync',
      refreshonly => true,
      subscribe   => Exec['post-nova_config'],
    }
  }

  # Remove auth configuration from api-paste.ini
  nova_paste_api_ini {
    'filter:authtoken/auth_uri':          ensure => absent;
    'filter:authtoken/auth_host':         ensure => absent;
    'filter:authtoken/auth_port':         ensure => absent;
    'filter:authtoken/auth_protocol':     ensure => absent;
    'filter:authtoken/admin_tenant_name': ensure => absent;
    'filter:authtoken/admin_user':        ensure => absent;
    'filter:authtoken/admin_password':    ensure => absent;
    'filter:authtoken/auth_admin_prefix': ensure => absent;
  }

}
