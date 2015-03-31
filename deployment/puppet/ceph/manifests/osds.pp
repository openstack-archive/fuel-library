# prepare and bring online the devices listed in $::ceph::osd_devices
class ceph::osds (
  $devices = $::ceph::osd_devices,
){

  firewall { '011 ceph-osd allow':
    chain  => 'INPUT',
    dport  => '6800-7100',
    proto  => 'tcp',
    action => accept,
  } ->

  ceph::osds::osd{ $devices: }

}
