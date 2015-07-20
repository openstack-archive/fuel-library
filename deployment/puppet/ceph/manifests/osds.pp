# == Class: ceph::osd
#
# Prepare and bring online the OSD devices
#
# ==== Parameters
#
# [*devices*]
# (optional) Array. This is the list of OSD devices identified by the facter.
#
# [*use_prepared_devices*]
# (optional) Boolean. Tells if OSD devices are prepared in advance. Defaults to
# the value defined in the class 'ceph'.
#
class ceph::osds (
  $devices = $::ceph::osd_devices,
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
