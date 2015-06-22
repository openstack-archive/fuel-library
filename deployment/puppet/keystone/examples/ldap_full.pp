# A full example from a real deployment that allows Keystone to modify
# everything except users, uses enabled_emulation, and ldaps

# Ensure this matches what is in LDAP or keystone will try to recreate
# the admin user
class { '::keystone::roles::admin':
  email    => 'test@example.com',
  password => 'ChangeMe',
}

# You can test this connection with ldapsearch first to ensure it works.
# LDAP configurations are *highly* dependent on your setup and this file
# will need to be tweaked. This sample talks to ldap.example.com, here is
# an example of ldapsearch that will search users on this box:
# ldapsearch -v -x -H 'ldap://example.com:389' -D \
# "uid=bind,cn=users,cn=accounts,dc=example,dc=com" -w SecretPass \
# -b cn=users,cn=accounts,dc=example,dc=com
class { '::keystone:ldap':
  url                          => 'ldap://ldap.example.com:389',
  user                         => 'uid=bind,cn=users,cn=accounts,dc=example,dc=com',
  password                     => 'SecretPass',
  suffix                       => 'dc=example,dc=com',
  query_scope                  => 'sub',
  user_tree_dn                 => 'cn=users,cn=accounts,dc=example,dc=com',
  user_id_attribute            => 'uid',
  user_name_attribute          => 'uid',
  user_mail_attribute          => 'mail',
  user_allow_create            => 'False',
  user_allow_update            => 'False',
  user_allow_delete            => 'False',
  user_enabled_emulation       => 'True',
  user_enabled_emulation_dn    => 'cn=openstack-enabled,cn=groups,cn=accounts,dc=example,dc=com',
  group_tree_dn                => 'ou=groups,ou=openstack,dc=example,dc=com',
  group_objectclass            => 'organizationalRole',
  group_id_attribute           => 'cn',
  group_name_attribute         => 'cn',
  group_member_attribute       => 'RoleOccupant',
  group_desc_attribute         => 'description',
  group_allow_create           => 'True',
  group_allow_update           => 'True',
  group_allow_delete           => 'True',
  project_tree_dn              => 'ou=projects,ou=openstack,dc=example,dc=com',
  project_objectclass          => 'organizationalUnit',
  project_id_attribute         => 'ou',
  project_member_attribute     => 'member',
  project_name_attribute       => 'ou',
  project_desc_attribute       => 'description',
  project_allow_create         => 'True',
  project_allow_update         => 'True',
  project_allow_delete         => 'True',
  project_enabled_emulation    => 'True',
  project_enabled_emulation_dn => 'cn=enabled,ou=openstack,dc=example,dc=com',
  role_tree_dn                 => 'ou=roles,ou=openstack,dc=example,dc=com',
  role_objectclass             => 'organizationalRole',
  role_id_attribute            => 'cn',
  role_name_attribute          => 'cn',
  role_member_attribute        => 'roleOccupant',
  role_allow_create            => 'True',
  role_allow_update            => 'True',
  role_allow_delete            => 'True',
  identity_driver              => 'keystone.identity.backends.ldap.Identity',
  assignment_driver            => 'keystone.assignment.backends.ldap.Assignment',
  use_tls                      => 'True',
  tls_cacertfile               => '/etc/ssl/certs/ca-certificates.crt',
  tls_req_cert                 => 'demand',
  use_pool                     => 'True',
  use_auth_pool                => 'True',
  pool_size                    => 5,
  auth_pool_size               => 5,
  pool_retry_max               => 3,
  pool_connection_timeout      => 120,
}
