# Example using LDAP to manage user identity only.
# This setup will not allow changes to users.

# Ensure this matches what is in LDAP or keystone will try to recreate
# the admin user
class { 'keystone::roles::admin':
  email    => 'test@example.com',
  password => 'ChangeMe',
}

# You can test this connection with ldapsearch first to ensure it works.
# This was tested against a FreeIPA box, you will likely need to change the
# attributes to match your configuration.
class { 'keystone:ldap':
  identity_driver       => 'keystone.identity.backends.ldap.Identity',
  url                   => 'ldap://ldap.example.com:389',
  user                  => 'uid=bind,cn=users,cn=accounts,dc=example,dc=com',
  password              => 'SecretPass',
  suffix                => 'dc=example,dc=com',
  query_scope           => 'sub',
  user_tree_dn          => 'cn=users,cn=accounts,dc=example,dc=com',
  user_id_attribute     => 'uid',
  user_name_attribute   => 'uid',
  user_mail_attribute   => 'mail',
  user_allow_create     => 'False',
  user_allow_update     => 'False',
  user_allow_delete     => 'False'
}
