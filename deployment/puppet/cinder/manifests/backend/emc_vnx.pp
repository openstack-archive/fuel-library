#
# == Define: cinder::backend::emc_vnx
#
# Setup Cinder to use the EMC VNX driver.
# Compatible for multiple backends
#
# == Parameters
#
# [*volume_backend_name*]
#   (optional) Allows for the volume_backend_name to be separate of $name.
#   Defaults to: $name
#
# [*san_ip*]
#   (required) IP address of SAN controller.
#
# [*san_password*]
#   (required) Password of SAN controller.
#
# [*san_login*]
#   (optional) Login of SAN controller.
#   Defaults to : 'admin'
#
# [*storage_vnx_pool_name*]
#   (required) Storage pool name.
#
# [*default_timeout*]
#   (optional) Default timeout for CLI operations in minutes.
#   Defaults to: '10'
#
# [*max_luns_per_storage_group*]
#   (optional) Default max number of LUNs in a storage group.
#   Defaults to: '256'
#
# [*package_ensure*]
#   (optional) The state of the package
#   Defaults to: 'present'
#
define cinder::backend::emc_vnx (
  $iscsi_ip_address,
  $san_ip,
  $san_password,
  $storage_vnx_pool_name,
  $default_timeout            = '10',
  $max_luns_per_storage_group = '256',
  $package_ensure             = 'present',
  $san_login                  = 'admin',
  $volume_backend_name        = $name,
) {

  include cinder::params

  cinder_config {
    "${name}/default_timeout":            value => $default_timeout;
    "${name}/iscsi_ip_address":           value => $iscsi_ip_address;
    "${name}/max_luns_per_storage_group": value => $max_luns_per_storage_group;
    "${name}/naviseccli_path":            value => '/opt/Navisphere/bin/naviseccli';
    "${name}/san_ip":                     value => $san_ip;
    "${name}/san_login":                  value => $san_login;
    "${name}/san_password":               value => $san_password;
    "${name}/storage_vnx_pool_name":      value => $storage_vnx_pool_name;
    "${name}/volume_backend_name":        value => $volume_backend_name;
    "${name}/volume_driver":              value => 'cinder.volume.drivers.emc.emc_cli_iscsi.EMCCLIISCSIDriver';
  }

}
