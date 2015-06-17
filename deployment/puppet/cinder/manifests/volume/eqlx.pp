# == define: cinder::volume::eqlx
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
class cinder::volume::eqlx (
  $san_ip,
  $san_login,
  $san_password,
  $san_thin_provision          = true,
  $eqlx_group_name             = 'group-0',
  $eqlx_pool                   = 'default',
  $eqlx_use_chap               = false,
  $eqlx_chap_login             = 'chapadmin',
  $eqlx_chap_password          = '12345',
  $eqlx_cli_timeout            = 30,
  $eqlx_cli_max_retries        = 5,
) {
  cinder::backend::eqlx { 'DEFAULT':
    san_ip               => $san_ip,
    san_login            => $san_login,
    san_password         => $san_password,
    san_thin_provision   => $san_thin_provision,
    eqlx_group_name      => $eqlx_group_name,
    eqlx_pool            => $eqlx_pool,
    eqlx_use_chap        => $eqlx_use_chap,
    eqlx_chap_login      => $eqlx_chap_login,
    eqlx_chap_password   => $eqlx_chap_password,
    eqlx_cli_timeout     => $eqlx_cli_timeout,
    eqlx_cli_max_retries => $eqlx_cli_max_retries,
  }
}
