# Example using v3 domains.  The admin user is created in the domain
# named 'admin_domain', and assigned the role 'admin' in the 'admin'
# project in the domain 'admin_domain'.  The keystone service account is
# created in default domain, and assigned the
# role 'admin' in the project 'services' in the default domain.
# NOTE: Until all of the other services support using Keystone v3
# with keystone_authtoken middleware that supports v3, they cannot
# specify a domain for authentication, and so have to be in the
# default domain.
#
# To be sure everything is working, run:
#   $ export OS_IDENTITY_API_VERSION=3
#   $ export OS_USERNAME=admin
#   $ export OS_USER_DOMAIN_NAME=admin_domain
#   $ export OS_PASSWORD=ChangeMe
#   $ export OS_PROJECT_NAME=admin
#   $ export OS_PROJECT_DOMAIN_NAME=admin_domain
#   $ export OS_AUTH_URL=http://keystone.local:35357/v3
#   $ openstack user list
#

Exec { logoutput => 'on_failure' }


class { '::mysql::server': }
class { '::keystone::db::mysql':
  password => 'keystone',
}
class { '::keystone':
  verbose             => true,
  debug               => true,
  database_connection => 'mysql://keystone:keystone@127.0.0.1/keystone',
  admin_token         => 'admin_token',
  enabled             => true,
}
class { '::keystone::roles::admin':
  email               => 'test@example.tld',
  password            => 'a_big_secret',
  admin               => 'admin', # username
  admin_tenant        => 'admin', # project name
  admin_user_domain   => 'admin', # domain for user
  admin_tenant_domain => 'admin', # domain for project
}
class { '::keystone::endpoint':
  public_url => 'http://127.0.0.1:5000/',
  admin_url  => 'http://127.0.0.1:35357/',
}
