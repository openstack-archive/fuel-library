# == Class: cinder::volume::solidfire
#
# Configures Cinder volume SolidFire driver.
# Parameters are particular to each volume driver.
#
# === Parameters
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
class cinder::volume::solidfire(
  $san_ip,
  $san_login,
  $san_password,
  $volume_driver       = 'cinder.volume.drivers.solidfire.SolidFire',
  $sf_emulate_512      = true,
  $sf_allow_tenant_qos = false,
  $sf_account_prefix   = '',
  $sf_api_port         = '443'
) {

  cinder::backend::solidfire { 'DEFAULT':
    san_ip              => $san_ip,
    san_login           => $san_login,
    san_password        => $san_password,
    volume_driver       => $volume_driver,
    sf_emulate_512      => $sf_emulate_512,
    sf_allow_tenant_qos => $sf_allow_tenant_qos,
    sf_account_prefix   => $sf_account_prefix,
    sf_api_port         => $sf_api_port,
  }
}
