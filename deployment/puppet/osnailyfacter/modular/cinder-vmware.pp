notice('MODULAR: cinder-vmware.pp')

# pulling hiera
$vcenter_hash                   = hiera('vcenter', {})

$vmware_host_ip                 = $vcenter_hash['host_ip']
$vmware_host_username           = $vcenter_hash['vc_user']
$vmware_host_password           = $vcenter_hash['vc_password']
$vmware_clusters                = $vcenter_hash['cluster']

$nodes_hash                     = hiera('nodes', {})
$roles                          = node_roles($nodes_hash, hiera('uid'))

$cinder_hash                    = hiera('cinder', {})
$cinder_password                = $cinder_hash['user_password']

if (member($roles, 'cinder-vmware')) {
  class {'cinder::volume':

  }
  class {'vmware::cinder':
    vmware_host_ip            => $vmware_host_ip,
    vmware_host_username      => $vmware_host_username,
    vmware_host_password      => $vmware_host_password,
    vmware_cluster            => $vmware_clusters,
    storage_availability_zone => 'non-nova',
    default_availability_zone => 'non-nova',
    cinder_password           => $cinder_password,
    debug                     => hiera('debug', true)
  }
}
