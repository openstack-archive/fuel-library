# == Class: cinder::backend::solidfire
#
# Configures Cinder volume SolidFire driver.
# Parameters are particular to each volume driver.
#
# === Parameters
#
# [*volume_backend_name*]
#   (optional) Allows for the volume_backend_name to be separate of $name.
#   Defaults to: $name
#
# [*volume_driver*]
#   (optional) Setup cinder-volume to use SolidFire volume driver.
#   Defaults to 'cinder.volume.drivers.solidfire.SolidFire'
#
# [*san_ip*]
#   (required) IP address of SolidFire clusters MVIP.
#
# [*san_login*]
#   (required) Username for SolidFire admin account.
#
# [*san_password*]
#   (required) Password for SolidFire admin account.
#
# [*sf_emulate_512*]
#   (optional) Use 512 byte emulation for volumes.
#   Defaults to True
#
# [*sf_allow_tenant_qos*]
#   (optional) Allow tenants to specify QoS via volume metadata.
#   Defaults to False
#
# [*sf_account_prefix*]
#   (optional) Prefix to use when creating tenant accounts on SolidFire Cluster.
#   Defaults to None, so account name is simply the tenant-uuid
#
# [*sf_api_port*]
#   (optional) Port ID to use to connect to SolidFire API.
#   Defaults to 443
#
define cinder::backend::solidfire(
  $san_ip,
  $san_login,
  $san_password,
  $volume_backend_name = $name,
  $volume_driver       = 'cinder.volume.drivers.solidfire.SolidFire',
  $sf_emulate_512      = true,
  $sf_allow_tenant_qos = false,
  $sf_account_prefix   = '',
  $sf_api_port         = '443'
) {

  cinder_config {
    "${name}/volume_backend_name": value => $volume_backend_name;
    "${name}/volume_driver":       value => $volume_driver;
    "${name}/san_ip":              value => $san_ip;
    "${name}/san_login":           value => $san_login;
    "${name}/san_password":        value => $san_password;
    "${name}/sf_emulate_512":      value => $sf_emulate_512;
    "${name}/sf_allow_tenant_qos": value => $sf_allow_tenant_qos;
    "${name}/sf_account_prefix":   value => $sf_account_prefix;
    "${name}/sf_api_port":         value => $sf_api_port;
  }
}
