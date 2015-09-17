# == Class: heat::keystone::domain
#
# Configures Heat domain in Keystone.
#
# === Parameters
#
# [*domain_name*]
#   Heat domain name. Defaults to 'heat'.
#
# [*domain_admin*]
#   Keystone domain admin user which will be created. Defaults to 'heat_admin'.
#
# [*domain_admin_email*]
#   Keystone domain admin user email address. Defaults to 'heat_admin@localhost'.

# [*domain_password*]
#   Keystone domain admin user password. Defaults to 'changeme'.
#
# === Deprecated Parameters
#
# [*auth_url*]
#   Keystone auth url
#
# [*keystone_admin*]
#   Keystone admin user
#
# [*keystone_password*]
#   Keystone admin password
#
# [*keystone_tenant*]
#   Keystone admin tenant name
#
class heat::keystone::domain (
  $domain_name        = 'heat',
  $domain_admin       = 'heat_admin',
  $domain_admin_email = 'heat_admin@localhost',
  $domain_password    = 'changeme',

  # DEPRECATED PARAMETERS
  $auth_url           = undef,
  $keystone_admin     = undef,
  $keystone_password  = undef,
  $keystone_tenant    = undef,
) {

  include ::heat::params

  if $auth_url {
    warning('The auth_url parameter is deprecated and will be removed in future releases')
  }
  if $keystone_admin {
    warning('The keystone_admin parameter is deprecated and will be removed in future releases')
  }
  if $keystone_password {
    warning('The keystone_password parameter is deprecated and will be removed in future releases')
  }
  if $keystone_tenant {
    warning('The keystone_tenant parameter is deprecated and will be removed in future releases')
  }

  ensure_resource('keystone_domain', 'heat_domain', {
    'ensure'  => 'present',
    'enabled' => true,
    'name'    => $domain_name
  })
  ensure_resource('keystone_user', 'heat_domain_admin', {
    'ensure'   => 'present',
    'enabled'  => true,
    'name'     => $domain_admin,
    'email'    => $domain_admin_email,
    'password' => $domain_password,
    'domain'   => $domain_name,
  })
  ensure_resource('keystone_user_role', "${domain_admin}@::${domain_name}", {
    'roles' => ['admin'],
  })

  heat_config {
    'DEFAULT/stack_domain_admin':          value => $domain_admin;
    'DEFAULT/stack_domain_admin_password': value => $domain_password, secret => true;
    'DEFAULT/stack_user_domain_name':      value => $domain_name;
  }
}
