#
# This define can be used to manage authtokens so that
# services can authenticate with keystone.
#
# == Parameters
#  [name] Name of the target file for the authtoken fragment.
#  [order] Used to determine the order of the fragments. Optional.
#    Defaults to 80, which places it near to the end of the file.
#  [admin_token] Keystone admin token that can serve as a shared secret
#    for authenticating. If this is choosen if is used instead of a user,tenant,password.
#    Optional. Defaults to false.
#  [admin_user] User used to authenticate service.
#    Optional. Defaults to admin
#  [admin_tenant_name] Tenant used to authenticate service.
#    Optional. Defaults to openstack.
#  [admin_password] Password used with user to authenticate service.
#    Optional. Defaults to ChangeMe.
#  [admin_tenant_name]
#    Optional. Defaults to openstack.
#  [auth_host] Host providing the keystone service API endpoint. Optional.
#    Defaults to 127.0.0.1
#  [auth_port] Port where keystone service is listening. Optional.
#    Defaults to 35357.
#  [auth_protocol] Protocol to use to communicate with keystone. Optional.
#    Defaults to http.
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#
define keystone::client::authtoken(
  $order               = '80',
  $admin_token         = false,
  $admin_user          = 'admin',
  $admin_tenant_name   = 'openstack',
  $admin_password      = 'ChangeMe',
  $delay_auth_decision = '0',
  $auth_host           = '127.0.0.1',
  $auth_port           = '35357',
  $auth_protocol       = 'http',
  $signing_dir         = undef,
  # TODO implement these eventually
  # $memcache_servers
  # $token_cache_time
) {

  $auth_uri = "${auth_protocol}://${auth_host}:${auth_port}"
  $fragment_title    = regsubst($name, '/', '_', 'G')

  concat::fragment { "${fragment_title}_authtoken":
    target  => $name,
    content => template('keystone/client/authtoken.conf.erb'),
    order   => $order,
  }

  include 'keystone::python'

}
