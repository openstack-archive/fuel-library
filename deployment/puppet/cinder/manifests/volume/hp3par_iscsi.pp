# == Class: cinder::volume::hp3par
#
# Configures Cinder volume HP 3par driver.
# Parameters are particular to each volume driver.
#
# === Parameters
#
# [*volume_driver*]
#   (optional) Setup cinder-volume to use HP 3par volume driver.
#   Defaults to 'cinder.volume.drivers.san.hp.hp_3par_iscsi.HP3PARISCSIDriver'
#
# [*san_ip*]
#   (required) IP address of HP 3par service processor.
#
# [*san_login*]
#   (required) Username for HP 3par account.
#
# [*san_password*]
#   (required) Password for HP 3par account.
#
# [*hp3par_api_url*]
#   (required) url for api access to 3par - expample https://10.x.x.x:8080/api/v1
#
# [*hp3par_username*]
#   (required) Username for HP3par admin user
#
# [*hp3par_password*]
#   (required) Password for hp3par_username
#
# [*hp3par_iscsi_ips*]
#   (required) iscsi ip addresses for the HP 3par array
#
# [*hp3par_iscsi_chap_enabled*]
#   (required) setting to false by default
#
# [*hp3par_snap_cpg*]
#   (optional) set to hp3par_cfg by default in the cinder driver
#
# [*hp3par_snapshot_retention*]
#   (required) setting to 48 hours as default expiration - ensures snapshot cannot be deleted prior to expiration
#
# [*hp3par_snapshot_expiration*]
#   (required) setting to 72 hours as default (must be larger than retention)
#
# [*extra_options*]
#   (optional) Hash of extra options to pass to the backend stanza
#   Defaults to: {}
#   Example :
#     { 'h3par_iscsi_backend/param1' => { 'value' => value1 } }
#
class cinder::volume::hp3par_iscsi(
  $hp3par_api_url,
  $hp3par_username,
  $hp3par_password,
  $san_ip,
  $san_login,
  $san_password,
  $volume_driver       = 'cinder.volume.drivers.san.hp.hp_3par_iscsi.HP3PARISCSIDriver',
  $hp3par_iscsi_ips,
  $hp3par_iscsi_chap_enabled = false,
  $hp3par_snap_cpg = OpenstackCPG,
  $hp3par_snapshot_retention = 48,
  $hp3par_snapshot_expiration = 72,
  $extra_options              = {},
) {

  cinder::backend::hp3par_iscsi { 'DEFAULT':
    volume_driver              => $volume_driver,
    hp3par_username            => $hp3par_username,
    hp3par_password            => $hp3par_password,
    san_ip                     => $san_ip,
    san_login                  => $san_login,
    san_password               => $san_password,
    hp3par_iscsi_ips           => $hp3par_iscsi_ips,
    hp3par_api_url             => $hp3par_api_url,
    hp3par_snap_cpg            => $hp3par_snap_cpg,
    hp3par_snapshot_retention  => $hp3par_snapshot_retention,
    hp3par_snapshot_expiration => $hp3par_snapshot_expiration,
    extra_options              => $extra_options,
  }
}
