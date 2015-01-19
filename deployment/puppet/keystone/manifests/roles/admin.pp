#
# This class implements some reasonable admin defaults for keystone.
#
# It creates the following keystone objects:
#   * service tenant (tenant used by all service users)
#   * "admin" tenant (defaults to "openstack")
#   * admin user (that defaults to the "admin" tenant)
#   * admin role
#   * adds admin role to admin user on the "admin" tenant
#
# [*Parameters*]
#
# [email] The email address for the admin. Required.
# [password] The admin password. Required.
# [admin_tenant] The name of the tenant to be used for admin privileges. Optional. Defaults to openstack.
# [admin] Admin user. Optional. Defaults to admin.
#
# [allow_add_user] Allow create user in authentication server. Optional. Defaults to true.
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
class keystone::roles::admin(
  $email,
  $password,
  $admin          = 'admin',
  $admin_tenant   = 'openstack',
  $service_tenant = 'services',
  $allow_add_user = true
) {

  keystone_tenant { $service_tenant:
    ensure      => present,
    enabled     => true,
    description => 'Tenant for the openstack services',
  }
  keystone_tenant { $admin_tenant:
    ensure      => present,
    enabled     => true,
    description => 'admin tenant',
  }
  if ($allow_add_user != false) {
    keystone_user { $admin:
      ensure      => present,
      enabled     => true,
      tenant      => $admin_tenant,
      email       => $email,
      password    => $password,
    }
  }
  keystone_role { 'admin':
    ensure => present,
  }

  keystone_role { '_member_':
    ensure => present,
  }

  if !defined(Keystone_user_role["${admin}@${admin_tenant}"]) {
    keystone_user_role { "${admin}@${admin_tenant}":
      roles  => 'admin',
      ensure => present,
    }
  }

}
