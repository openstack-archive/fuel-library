#
# Creates the auth endpoints for keystone
#
# * public_address   - public address for keystone endpoint. Optional. Defaults to 127.0.0.1.
# * admin_address    - admin address for keystone endpoint. Optional. Defaults to 127.0.0.1.
# * internal_address - internal address for keystone endpoint. Optional. Defaults to 127.0.0.1.
# * public_port      - Port for non-admin access to keystone endpoint. Optional. Defaults to 5000.
# * admin_port       - Port for admin access to keystone endpoint. Optional. Defaults to 35357.
#
class keystone::endpoint(
  $public_address   = '127.0.0.1',
  $admin_address    = '127.0.0.1',
  $internal_address = '127.0.0.1',
  $public_port      = '5000',
  $admin_port       = '35357'
) {
  keystone_service { 'keystone':
    ensure      => present,
    type        => 'identity',
    description => 'OpenStack Identity Service',
  }
  keystone_endpoint { 'keystone':
    ensure       => present,
    public_url   => "http://${public_address}:${public_port}/v2.0",
    admin_url    => "http://${admin_address}:${admin_port}/v2.0",
    internal_url => "http://${internal_address}:${public_port}/v2.0",
  }
}
