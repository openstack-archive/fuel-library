notice('MODULAR: cinder-vmware.pp')

$nodes_hash = hiera('nodes', {})
$roles      = node_roles($nodes_hash, hiera('uid'))

if (member($roles, 'cinder-vmware')) {
  $vc       = hiera('vcenter', {})
  $debug    = hiera('debug', true)
  $cmps     = rehash_vmware($vc['computes'], $debug)
  create_resources(vmware::cinder::vmdk, $cmps)
}
