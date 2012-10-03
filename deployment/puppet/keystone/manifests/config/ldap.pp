#
# This class implements a config fragment for
# the ldap specific backend for keystone.
#
# == Dependencies
# == Examples
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#
class keystone::ldap(
  $url            = 'ldap://localhost',
  $user           = 'dc=Manager,dc=example,dc=com',
  $password       = 'None',
  $suffix         = 'cn=example,cn=com',
  $user_tree_dn   = 'ou=Users,dc=example,dc=com',
  $tenant_tree_dn = 'ou=Roles,dc=example,dc=com',
  $role_tree_dn   = 'dc=example,dc=com'
) {

  keystone_config {
    'ldap/url':            value => $url;
    'ldap/user':           value => $user;
    'ldap/password':       value => $password;
    'ldap/suffix':         value => $suffix;
    'ldap/user_tree_dn':   value => $user_tree_dn;
    'ldap/tenant_tree_dn': value => $tenant_tree_dn;
    'ldap/role_tree_dn':   value => $role_tree_dn;
    #"ldap/tree_dn" value => "dc=example,dc=com",
  }
}
