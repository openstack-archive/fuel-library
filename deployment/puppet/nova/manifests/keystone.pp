# configure to use keystone
class nova_keystone(
) {

  nova_config {
    'use_deprecated_auth': value => false;
    'auth_strategy'      : value => 'keystone';
    'keystone_ec2_url'   : value => 'http://10.42.0.6:5000/v2.0/ec2tokens';
  }

}
