#
# Creates the auth endpoints for keystone
#
class keystone::endpoint(
  $address    = '127.0.0.1',
  $public_url = '5000',
  $admin_url  = '35357'
) {
  keystone_service { 'keystone':
    ensure      => present,
    type        => 'identity',
    description => 'OpenStack Identity Service',
  }
  keystone_endpoint { 'keystone':
    ensure       => present,
    public_url   => "http://${address}:${public_url}/v2.0",
    admin_url    => "http://${address}:${admin_url}/v2.0",
    internal_url => "http://${address}:${public_url}/v2.0",
  }
}
