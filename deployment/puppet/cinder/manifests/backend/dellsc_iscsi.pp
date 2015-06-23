# == define: cinder::backend::dellsc_iscsi
#
# Configure the Dell Storage Center ISCSI Driver for cinder.
#
# === Parameters
#
# [*san_ip*]
#   (required) IP address of Enterprise Manager.
#
# [*san_login*]
#   (required) Enterprise Manager user name.
#
# [*san_password*]
#   (required) Enterprise Manager user password.
#
# [*iscsi_ip_address*]
#   (required) The Storage Center iSCSI IP address.
#
# [*dell_sc_ssn*]
#   (required) The Storage Center serial number to use.
#
# [*volume_backend_name*]
#   (optional) The storage backend name.
#   Defaults to the name of the backend
#
# [*dell_sc_api_port*]
#   (optional) The Enterprise Manager API port.
#   Defaults to 3033
#
# [*dell_sc_server_folder*]
#   (optional) Name of the server folder to use on the Storage Center.
#   Defaults to 'srv'
#
# [*dell_sc_volume_folder*]
#   (optional) Name of the volume folder to use on the Storage Center.
#   Defaults to 'vol'
#
# [*iscsi_port*]
#   (optional) The ISCSI IP Port of the Storage Center.
#   Defaults to 3260
#
# [*extra_options*]
#   (optional) Hash of extra options to pass to the backend stanza.
#   Defaults to: {}
#   Example:
#     { 'dellsc_iscsi_backend/param1' => { 'value' => value1 } }
#
define cinder::backend::dellsc_iscsi (
  $san_ip,
  $san_login,
  $san_password,
  $iscsi_ip_address,
  $dell_sc_ssn,
  $volume_backend_name   = $name,
  $dell_sc_api_port      = 3033,
  $dell_sc_server_folder = 'srv',
  $dell_sc_volume_folder = 'vol',
  $iscsi_port            = 3260,
  $extra_options         = {},
) {
  $driver = 'dell.dell_storagecenter_iscsi.DellStorageCenterISCSIDriver'
  cinder_config {
    "${name}/volume_backend_name":   value => $volume_backend_name;
    "${name}/volume_driver":         value => "cinder.volume.drivers.${driver}";
    "${name}/san_ip":                value => $san_ip;
    "${name}/san_login":             value => $san_login;
    "${name}/san_password":          value => $san_password, secret => true;
    "${name}/iscsi_ip_address":      value => $iscsi_ip_address;
    "${name}/dell_sc_ssn":           value => $dell_sc_ssn;
    "${name}/dell_sc_api_port":      value => $dell_sc_api_port;
    "${name}/dell_sc_server_folder": value => $dell_sc_server_folder;
    "${name}/dell_sc_volume_folder": value => $dell_sc_volume_folder;
    "${name}/iscsi_port":            value => $iscsi_port;
  }

  create_resources('cinder_config', $extra_options)

}
