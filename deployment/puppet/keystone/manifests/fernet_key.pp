# generate and install keys for Keystone Fernet tokens

class keystone::fernet_key {

  $keystone_config = '/etc/keystone/keystone.conf'
  $staged_key     = '/etc/keystone/fernet-keys/0'
  $primary_key    = '/etc/keystone/fernet-keys/1'

  install_fernet_keys {'keys_for_keystone_fernet_token':
     ensure           => present,
     user             => 'keystone',
     staged_key_path  => $staged_key,
     primary_key_path => $private_key,

   }

Install_fernet_keys['keys_for_keystone_fernet_token'] ~> Service[keystone]

}
                                 
