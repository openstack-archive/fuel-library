#
# This class can be used to manage keystone's authtoken middleware
# for swift proxy
#
# == Parameters
#  [admin_token] Keystone admin token that can serve as a shared secret
#    for authenticating. If this is choosen if is used instead of a user,tenant,password.
#    Optional. Defaults to false.
#  [admin_user] User used to authenticate service.
#    Optional. Defaults to admin
#  [admin_tenant_name] Tenant used to authenticate service.
#    Optional. Defaults to openstack.
#  [admin_password] Password used with user to authenticate service.
#    Optional. Defaults to ChangeMe.
#  [delay_decision] Set to 1 to support token-less access (anonymous access,
#    tempurl, …)
#    Optional, Defaults to 0
#  [auth_host] Host providing the keystone service API endpoint. Optional.
#    Defaults to 127.0.0.1
#  [auth_port] Port where keystone service is listening. Optional.
#    Defaults to 3557.
#  [auth_protocol] Protocol to use to communicate with keystone. Optional.
#    Defaults to https.
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#

class swift::proxy::authtoken(
  $admin_token         = undef,
  $admin_user          = undef,
  $admin_tenant_name   = undef,
  $admin_password      = undef,
  $delay_auth_decision = undef,
  $auth_host           = undef,
  $auth_port           = undef,
  $auth_protocol       = undef
) {

  keystone::client::authtoken { '/etc/swift/proxy-server.conf':
    admin_token         => $admin_token,
    admin_user          => $admin_user,
    admin_tenant_name   => $admin_tenant_name,
    admin_password      => $admin_password,
    delay_auth_decision => $delay_auth_decision,
    auth_host           => $auth_host,
    auth_port           => $auth_port,
    auth_protocol       => $auth_protocol,
    signing_dir         => '/tmp/keystone-signing-swift',
  }

}
