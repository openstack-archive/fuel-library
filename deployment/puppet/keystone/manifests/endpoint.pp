#
# Creates the auth endpoints for keystone
#
# == Parameters
#
# * public_address   - public address for keystone endpoint. Optional. Defaults to 127.0.0.1.
# * admin_address    - admin address for keystone endpoint. Optional. Defaults to 127.0.0.1.
# * internal_address - internal address for keystone endpoint. Optional. Defaults to 127.0.0.1.
# * public_port      - Port for non-admin access to keystone endpoint. Optional. Defaults to 5000.
# * admin_port       - Port for admin access to keystone endpoint. Optional. Defaults to 35357.
# * internal_port    - Port for internal access to keystone endpoint. Optional. Defaults to 35357.
# * region           - Region for endpoint. Optional. Defaults to RegionOne.
# * version          - API version for endpoint. Optional. Defaults to v2.0.
# * public_url       - public url for keystone endpoint. Optional. Defaults to undef. Overrides & will deprecate other public_ parameters.
# * internal_url     - internal url for keystone endpoint. Optional. Defaults to $public_url if undef. Overrides & will deprecate other internal_ parameters.
# * admin_url        - admin url for keystone endpoint. Optional. Defaults to undef. Overrides & will deprecate other admin_ parameters.
#
# == Sample Usage
#
#   class { 'keystone::endpoint':
#     :public_address   => '154.10.10.23',
#     :admin_address    => '10.0.0.7',
#     :internal_address => '11.0.1.7',
#   }
#
#
class keystone::endpoint(
  $public_address    = '127.0.0.1',
  $admin_address     = '127.0.0.1',
  $internal_address  = '127.0.0.1',
  $public_port       = '5000',
  $admin_port        = '35357',
  $internal_port     = undef,
  $region            = 'RegionOne',
  $version           = 'v2.0',
  $public_protocol   = 'http',
  $public_url        = undef,
  $internal_url      = undef,
  $admin_url         = undef,
) {

  if $internal_port == undef {
    $internal_port_real = $public_port
  } else {
    $internal_port_real = $internal_port
  }

  if $public_url {
    $public_url_real = "${public_url}/${version}"
  } else {
    $public_url_real = "${public_protocol}://${public_address}:${public_port}/${version}"
  }

  if $internal_url {
    $internal_url_real = "${internal_url}/${version}"
  } else {
    if $public_url {
      $internal_url_real = $public_url_real
    } else {
      $internal_url_real = "http://${internal_address}:${internal_port_real}/${version}"
    }
  }

  if $admin_url {
    $admin_url_real = "${admin_url}/${version}"
  } else {
    $admin_url_real = "http://${admin_address}:${admin_port}/${version}"
  }

  keystone_service { 'keystone':
    ensure      => present,
    type        => 'identity',
    description => 'OpenStack Identity Service',
  }

  keystone_endpoint { "${region}/keystone":
    ensure       => present,
    public_url   => $public_url_real,
    admin_url    => $admin_url_real,
    internal_url => $internal_url_real,
    region       => $region,
  }
}
