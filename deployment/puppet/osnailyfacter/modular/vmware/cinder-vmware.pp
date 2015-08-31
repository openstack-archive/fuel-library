notice('MODULAR: cinder-vmware.pp')

$nodes_hash   = hiera('nodes', {})
$roles        = node_roles($nodes_hash, hiera('uid'))
$cinder_hash  = hiera_hash('cinder_hash', {})

if (member($roles, 'cinder-vmware')) {
  $cinder   = $cinder_hash
  $debug    = pick($cinder_hash['debug'], hiera('debug', true))
  $volumes  = get_cinder_vmware_data($cinder['instances'], $debug)
  create_resources(vmware::cinder::vmdk, $volumes)
}
