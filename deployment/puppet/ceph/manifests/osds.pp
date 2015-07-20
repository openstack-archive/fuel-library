# == Class: ceph::osd
#
# Prepare and bring online the OSD devices
#
# ==== Parameters
#
# [*devices*]
# (optional) Array. This is the list of OSD devices identified by the facter.
#
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
