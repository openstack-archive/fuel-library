# == class keystone::fernet_key
#
# === parameters:
#
# [*staged_key*]
#   (Optional) path to generated staged fernet key
#   Defaults to: '/var/lib/astute/keystone/0'
#
# [*primary_key*]
#   (Optional) path to generated primary fernet key
#   generate and install keys for Keystone Fernet tokens
#   Defaults to: '/var/lib/astute/keystone/1'
#
class keystone::fernet_key(
  $staged_key     = '/var/lib/astute/keystone/0',
  $primary_key    = '/var/lib/astute/keystone/1',
) inherits ::keystone::params {

  install_fernet_keys {'keys_for_fernet_token':
    ensure           => present,
    user             => 'keystone',
    staged_key_path  => $staged_key,
    primary_key_path => $primary_key,
    staged_key_name  => '0',
    primary_key_name => '1',
    keystone_dir     => '/etc/keystone',
  }

  Install_fernet_keys['keys_for_fernet_token'] -> Service['keystone']

}
