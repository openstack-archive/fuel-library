# == define: cinder::backend::eqlx
#
# Configure the Dell EqualLogic driver for cinder.
#
# === Parameters
#
# [*san_ip*]
#   (required) The IP address of the Dell EqualLogic array.
#
# [*san_login*]
#   (required) The account to use for issuing SSH commands.
#
# [*san_password*]
#   (required) The password for the specified SSH account.
#
# [*san_thin_provision*]
#   (optional) Whether or not to use thin provisioning for volumes.
#   Defaults to true
#
# [*volume_backend_name*]
#   (optional) The backend name.
#   Defaults to the name of the resource
#
# [*eqlx_group_name*]
#   (optional) The CLI prompt message without '>'.
#   Defaults to 'group-0'
#
# [*eqlx_pool*]
#   (optional) The pool in which volumes will be created.
#   Defaults to 'default'
#
# [*eqlx_use_chap*]
#   (optional) Use CHAP authentification for targets?
#   Defaults to false
#
# [*eqlx_chap_login*]
#   (optional) An existing CHAP account name.
#   Defaults to 'chapadmin'
#
# [*eqlx_chap_password*]
#   (optional) The password for the specified CHAP account name.
#   Defaults to '12345'
#
# [*eqlx_cli_timeout*]
#   (optional) The timeout for the Group Manager cli command execution.
#   Defaults to 30 seconds
#
# [*eqlx_cli_max_retries*]
#   (optional) The maximum retry count for reconnection.
#   Defaults to 5
#
define cinder::backend::eqlx (
  $san_ip,
  $san_login,
  $san_password,
  $san_thin_provision   = true,
  $volume_backend_name  = $name,
  $eqlx_group_name      = 'group-0',
  $eqlx_pool            = 'default',
  $eqlx_use_chap        = false,
  $eqlx_chap_login      = 'chapadmin',
  $eqlx_chap_password   = '12345',
  $eqlx_cli_timeout     = 30,
  $eqlx_cli_max_retries = 5,
) {
  cinder_config {
    "${name}/volume_backend_name":  value => $volume_backend_name;
    "${name}/volume_driver":        value => 'cinder.volume.drivers.eqlx.DellEQLSanISCSIDriver';
    "${name}/san_ip":               value => $san_ip;
    "${name}/san_login":            value => $san_login;
    "${name}/san_password":         value => $san_password, secret => true;
    "${name}/san_thin_provision":   value => $san_thin_provision;
    "${name}/eqlx_group_name":      value => $eqlx_group_name;
    "${name}/eqlx_use_chap":        value => $eqlx_use_chap;
    "${name}/eqlx_cli_timeout":     value => $eqlx_cli_timeout;
    "${name}/eqlx_cli_max_retries": value => $eqlx_cli_max_retries;
    "${name}/eqlx_pool":            value => $eqlx_pool;
  }

  if(str2bool($eqlx_use_chap)) {
    cinder_config {
      "${name}/eqlx_chap_login":      value => $eqlx_chap_login;
      "${name}/eqlx_chap_password":   value => $eqlx_chap_password, secret => true;
    }
  }
}
