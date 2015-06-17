notice('MODULAR: vmware/compute-vmware.pp')

$role = hiera('role')

$debug = hiera('debug', true)
$ceilometer_hash = hiera_hash('ceilometer', {})

$vcenter_hash = hiera_hash('vcenter', {})
$computes_hash = parse_vcenter_settings($vcenter_hash['computes'])

$uid = hiera('uid')
$node_name = "node-$uid"
$defaults = { current_node => $node_name }

create_resources(vmware::compute_vmware, $computes_hash, $defaults)
