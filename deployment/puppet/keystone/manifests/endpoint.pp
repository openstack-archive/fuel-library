#
# Creates the auth endpoints for keystone
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
