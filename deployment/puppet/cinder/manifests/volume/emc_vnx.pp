# == Class: cinder::volume::emc_enx
#
# Configures Cinder volume EMC VNX driver.
# Parameters are particular to each volume driver.
#
# === Parameters
#
# [*package_ensure*]
#   (Optional) State of the package
#   Defaults to 'present'.
#
# [*iscsi_ip_address*]
#   (Required) The IP address that the iSCSI daemon is listening on
#
# [*san_ip*]
#   (Required) IP address of SAN controller.
#
# [*san_password*]
#   (Required) Password of SAN controller.
#
# [*san_login*]
#   (Optional) Login of SAN controller.
#   Defaults to : 'admin'
#
# [*storage_vnx_pool_name*]
#   (Required) Storage pool name.
#
# [*default_timeout*]
#   (Optonal) Default timeout for CLI operations in minutes.
#   Defaults to: '10'
#
# [*max_luns_per_storage_group*]
#   (Optonal) Default max number of LUNs in a storage group.
#   Defaults to: '256'
#
# [*extra_options*]
#   (optional) Hash of extra options to pass to the backend stanza
#   Defaults to: {}
#   Example :
#     { 'emc_vnx_backend/param1' => { 'value' => value1 } }
#
class cinder::volume::emc_vnx(
  $iscsi_ip_address,
  $san_ip,
  $san_password,
  $storage_vnx_pool_name,
  $default_timeout            = '10',
  $max_luns_per_storage_group = '256',
  $package_ensure             = 'present',
  $san_login                  = 'admin',
  $extra_options              = {},
) {

  cinder::backend::emc_vnx { 'DEFAULT':
    default_timeout            => $default_timeout,
    iscsi_ip_address           => $iscsi_ip_address,
    max_luns_per_storage_group => $max_luns_per_storage_group,
    package_ensure             => $package_ensure,
    san_ip                     => $san_ip,
    san_login                  => $san_login,
    san_password               => $san_password,
    storage_vnx_pool_name      => $storage_vnx_pool_name,
    extra_options              => $extra_options,
  }

}
