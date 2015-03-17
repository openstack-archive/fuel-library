notice('MODULAR: cinder-vmware.pp')

$nodes_hash = hiera('nodes', {})
$roles      = node_roles($nodes_hash, hiera('uid'))

if (member($roles, 'cinder-vmware')) {
  $cinder   = hiera('cinder', {})
  $debug    = hiera('debug', true)
  $volumes  = get_cinder_vmware_data($cinder['instances'], $debug)
  create_resources(vmware::cinder::vmdk, $volumes)
}
