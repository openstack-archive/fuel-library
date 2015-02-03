notice('MODULAR: cinder-vmware.pp')

# pulling hiera
$vcenter_hash             = hiera('vcenter', {})
$cmp                      = $vcenter_hash['computes'][0] # will be fixed in 7.1
$vmware_host_ip           = $cmp['vc_host']
$vmware_host_username     = $cmp['vc_user']
$vmware_host_password     = $cmp['vc_password']
$vmware_availability_zone = $cmp['availability_zone_name']
$vmware_clusters          = $cmp['vc_cluster']
$nodes_hash               = hiera('nodes', {})
$roles                    = node_roles($nodes_hash, hiera('uid'))


if (member($roles, 'cinder-vmware')) {
  class {'vmware::cinder':
    vmware_host_ip            => $vmware_host_ip,
    vmware_host_username      => $vmware_host_username,
    vmware_host_password      => $vmware_host_password,
    vmware_cluster            => $vmware_clusters,
    storage_availability_zone => $vmware_availabiilty_zone,
    default_availability_zone => $vmware_availabiilty_zone,
    debug                     => hiera('debug', true)
  }
}
