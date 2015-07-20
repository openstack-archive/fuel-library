# prepare and bring online the devices listed in $::ceph::osd_devices
class ceph::osds (
  $devices = $::ceph::osd_devices,
  # 'use_prepared_devices' parameter indicates that OSD devices are expected to
  # be prepared in advance. If set to true, 'ceph-deploy prepare' for all
  # devices will be skipped.
  $use_prepared_devices = $::ceph::use_prepared_devices
){

  firewall { '011 ceph-osd allow':
    chain  => 'INPUT',
    dport  => '6800-7100',
    proto  => 'tcp',
    action => accept,
  } ->

  ceph::osds::osd{ $devices:
    use_prepared_devices => $use_prepared_devices
  }

}
