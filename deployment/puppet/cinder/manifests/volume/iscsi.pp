#
class cinder::volume::iscsi (
  $iscsi_ip_address,
  $volume_driver     = 'cinder.volume.drivers.lvm.LVMISCSIDriver',
  $volume_group      = 'cinder-volumes',
  $iscsi_helper      = $::cinder::params::iscsi_helper,
) {

  include cinder::params

  cinder::backend::iscsi { 'DEFAULT':
    iscsi_ip_address   => $iscsi_ip_address,
    volume_driver      => $volume_driver,
    volume_group       => $volume_group,
    iscsi_helper       => $iscsi_helper
  }
}
