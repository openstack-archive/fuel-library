#
# This class implements some reasonable admin defaults for keystone.
#
# It relies on the Puppet native types that wrap the
# keystone client command line tool.
#
# It creates the following keystone objects:
#   - service tenant
#   - admin tenant
#   - admin user (that defaults to admin tenant)
#   - admin role
#   - Member role
#   - adds admin role to admin user on admin tenant
# [*Parameters*]
#
# [email] The email address for the admin. Optional. Defaults to demo@puppetlabs.com.
#    TODO should be required.
# [password] The admin password. Optional. Defaults to ChangeMe
#    TODO should be required.
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
  $email    = 'demo@puppetlabs.com',
  $password = 'ChangeMe'
) {

  keystone_tenant { 'services':
    ensure      => present,
    enabled     => 'True',
    description => 'Tenant for the openstack services',
  }
  keystone_tenant { 'admin':
    ensure      => present,
    enabled     => 'True',
    description => 'admin tenant',
  }
  keystone_user { 'admin':
    ensure      => present,
    enabled     => 'True',
    tenant      => 'admin',
    email       => $email,
    password    => $password,
  }
  keystone_role { ['admin', 'Member']:
    ensure => present,
  }
  keystone_user_role { 'admin@admin':
    roles  => 'admin',
    ensure => present,
  }

}
