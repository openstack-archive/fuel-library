class nailgun::tuningbox::auth(
  $address          = $::nailgun::tuningbox::params::keystone_host,
  $auth_name        = $::nailgun::tuningbox::params::keystone_user,
  $password         = $::nailgun::tuningbox::params::keystone_pass,
  $tenant           = $::nailgun::tuningbox::params::keystone_tenant,
  $app_name         = $::nailgun::tuningbox::params::app_name,
  $http_port        = $::nailgun::tuningbox::params::http_port,
  $https_port       = $::nailgun::tuningbox::params::https_port,
  $ssl_enabled      = $::nailgun::tuningbox::params::ssl_enabled,
  $service_type     = $::nailgun::tuningbox::params::service_type,
  $region           = 'RegionOne',
  $internal_address = undef,
  $admin_address    = undef,
  $public_address   = undef,
) inherits nailgun::tuningbox::params {

  $internal_address_real = pick($internal_address, $address)
  $admin_address_real    = pick($admin_address, $address)
  $public_address_real   = pick($public_address, $address)

  keystone_user { $auth_name:
    ensure   => present,
    enabled  => 'True',
    tenant   => $tenant,
    password => $password,
  }

  keystone_user_role { "${auth_name}@${tenant}":
    ensure => present,
    roles  => 'admin',
  }

  # http service/endpoint
  keystone_service { "${app_name}":
    ensure      => present,
    type        => "${service_type}",
    description => "${app_name}",
  }

  keystone_endpoint { "${region}/${app_name}":
    ensure       => present,
    public_url   => "http://${public_address_real}:${http_port}",
    admin_url    => "http://${admin_address_real}:${http_port}",
    internal_url => "http://${internal_address_real}:${http_port}",
  }

  # https service/endpoint
  if $ssl_enabled {
    $app_name_ssl = "${app_name}_ssl"

    keystone_service { "${app_name_ssl}":
      ensure      => present,
      type        => "${service_type}",
      description => "${app_name_ssl}",
    }

    keystone_endpoint { "${region}/${app_name_ssl}":
      ensure       => present,
      public_url   => "https://${public_address_real}:${https_port}",
      admin_url    => "https://${admin_address_real}:${https_port}",
      internal_url => "https://${internal_address_real}:${https_port}",
    }
  }
}
