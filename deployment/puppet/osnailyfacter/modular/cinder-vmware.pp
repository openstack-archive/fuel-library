notice('MODULAR: cinder-vmware.pp')

# pulling hiera
$vcenter_hash                   = hiera('vcenter', {})

class {'что-то про vmware/openstack::cinder-vmware':
  vmware_host_ip       => $vcenter_hash['host_ip'],
  vmware_host_username => $vcenter_hash['vc_user'],
  vmware_host_password => $vcenter_hash['vc_password']
}
