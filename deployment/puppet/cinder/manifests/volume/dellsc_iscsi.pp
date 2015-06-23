# == define: cinder::volume::dellsc_iscsi
#
# Configure the Dell Storage Center ISCSI driver for cinder.
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
#   (optional) The Storage Center iSCSI IP port.
#   Defaults to 3260
#
# [*extra_options*]
#   (optional) Hash of extra options to pass to the backend stanza.
#   Defaults to: {}
#   Example:
#     { 'dellsc_iscsi_backend/param1' => { 'value' => value1 } }
#
class cinder::volume::dellsc_iscsi (
  $san_ip,
  $san_login,
  $san_password,
  $iscsi_ip_address,
  $dell_sc_ssn,
  $dell_sc_api_port      = 3033,
  $dell_sc_server_folder = 'srv',
  $dell_sc_volume_folder = 'vol',
  $iscsi_port            = 3260,
  $extra_options         = {},
) {
  cinder::backend::dellsc_iscsi { 'DEFAULT':
    san_ip                => $san_ip,
    san_login             => $san_login,
    san_password          => $san_password,
    iscsi_ip_address      => $iscsi_ip_address,
    dell_sc_ssn           => $dell_sc_ssn,
    dell_sc_api_port      => $dell_sc_api_port,
    dell_sc_server_folder => $dell_sc_server_folder,
    dell_sc_volume_folder => $dell_sc_volume_folder,
    iscsi_port            => $iscsi_port,
    extra_options         => $extra_options,
  }
}
