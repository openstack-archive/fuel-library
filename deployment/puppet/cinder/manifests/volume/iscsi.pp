#
class cinder::volume::iscsi (
  $iscsi_ip_address,
  $volume_group      = 'cinder-volumes',
  $iscsi_helper      = $cinder::params::iscsi_helper,
) {

  cinder::backend::iscsi { 'DEFAULT':
    iscsi_ip_address   => $iscsi_ip_address,
    volume_group       => $volume_group,
    iscsi_helper       => $iscsi_helper
  }
}
