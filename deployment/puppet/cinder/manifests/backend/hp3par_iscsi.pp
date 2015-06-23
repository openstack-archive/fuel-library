# == Define: cinder::backend::hp3par_iscsi
#
# Configures Cinder volume HP 3par ISCSI driver.
# Parameters are particular to each volume driver.
#
# === Parameters
#
# [*hp3par_api_url*]
#    (required) url for api access to 3par - example https://10.x.x.x:8080/api/v1
#
# [*hp3par_username*]
#    (required) Username for HP3par admin user
#
# [*hp3par_password*]
#    (required) Password for hp3par_username
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
# [*hp3par_iscsi_ips*]
#   (required) iscsi IP addresses for the HP 3par array
#   This is a list of IPs with ports in a string, for example:
#   '1.2.3.4:3261, 5.6.7.8:3261'
#
# [*volume_backend_name*]
#   (optional) Allows for the volume_backend_name to be separate of $name.
#   Defaults to: $name
#
# [*volume_driver*]
#   (optional) Setup cinder-volume to use HP 3par volume driver.
#   Defaults to 'cinder.volume.drivers.san.hp.hp_3par_iscsi.HP3PARISCSIDriver'
#
# [*hp3par_iscsi_chap_enabled
#   (required) setting to false by default
#
# [*hp3par_snap_cpg*]
#   (optional) set to hp3par_cfg by default in the cinder driver
#
# [*hp3par_snapshot_retention*]
#   (required) Time in hours for snapshot retention. Must be less
#   than hp3par_snapshot_expiration.
#   Defaults to 48.
#
# [*hp3par_snapshot_expiration*]
#   (required) Time in hours until a snapshot expires. Must be more
#   than hp3par_snapshot_retention.
#   Defaults to 72.
#
# [*extra_options*]
#   (optional) Hash of extra options to pass to the backend stanza
#   Defaults to: {}
#   Example :
#     { 'h3par_iscsi_backend/param1' => { 'value' => value1 } }
#
define cinder::backend::hp3par_iscsi(
  $hp3par_api_url,
  $hp3par_username,
  $hp3par_password,
  $san_ip,
  $san_login,
  $san_password,
  $hp3par_iscsi_ips,
  $volume_backend_name        = $name,
  $volume_driver              = 'cinder.volume.drivers.san.hp.hp_3par_iscsi.HP3PARISCSIDriver',
  $hp3par_iscsi_chap_enabled  = false,
  $hp3par_snap_cpg            = 'OpenstackCPG',
  $hp3par_snapshot_retention  = 48,
  $hp3par_snapshot_expiration = 72,
  $extra_options              = {},
) {

  if ($hp3par_snapshot_expiration <= $hp3par_snapshot_retention) {
    fail ('hp3par_snapshot_expiration must be greater than hp3par_snapshot_retention')
  }

  cinder_config {
    "${name}/volume_backend_name":        value => $volume_backend_name;
    "${name}/volume_driver":              value => $volume_driver;
    "${name}/hp3par_username":            value => $hp3par_username;
    "${name}/hp3par_password":            value => $hp3par_password, secret => true;
    "${name}/san_ip":                     value => $san_ip;
    "${name}/san_login":                  value => $san_login;
    "${name}/san_password":               value => $san_password, secret => true;
    "${name}/hp3par_iscsi_ips":           value => $hp3par_iscsi_ips;
    "${name}/hp3par_api_url":             value => $hp3par_api_url;
    "${name}/hp3par_iscsi_chap_enabled":  value => $hp3par_iscsi_chap_enabled;
    "${name}/hp3par_snap_cpg":            value => $hp3par_snap_cpg;
    "${name}/hp3par_snapshot_retention":  value => $hp3par_snapshot_retention;
    "${name}/hp3par_snapshot_expiration": value => $hp3par_snapshot_expiration;
  }

  create_resources('cinder_config', $extra_options)

}
