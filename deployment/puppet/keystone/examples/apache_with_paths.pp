# Example using apache to serve keystone
#
# To be sure everything is working, run:
#   $ export OS_USERNAME=admin
#   $ export OS_PASSWORD=ChangeMe
#   $ export OS_TENANT_NAME=openstack
#   $ export OS_AUTH_URL=http://keystone.local/keystone/main/v2.0
#   $ keystone catalog
#   Service: identity
#   +-------------+----------------------------------------------+
#   |   Property  |                    Value                     |
#   +-------------+----------------------------------------------+
#   |   adminURL  | http://keystone.local:80/keystone/admin/v2.0 |
#   |      id     |       4f0f55f6789d4c73a53c51f991559b72       |
#   | internalURL | http://keystone.local:80/keystone/main/v2.0  |
#   |  publicURL  | http://keystone.local:80/keystone/main/v2.0  |
#   |    region   |                  RegionOne                   |
#   +-------------+----------------------------------------------+
#

Exec { logoutput => 'on_failure' }

class { '::mysql::server': }
class { '::keystone::db::mysql':
  password => 'keystone',
}
class { '::keystone':
  verbose             => true,
  debug               => true,
  database_connection => 'mysql://keystone_admin:keystone@127.0.0.1/keystone',
  catalog_type        => 'sql',
  admin_token         => 'admin_token',
  enabled             => true,
}
class { '::keystone::cron::token_flush': }
class { '::keystone::roles::admin':
  email    => 'test@puppetlabs.com',
  password => 'ChangeMe',
}
class { '::keystone::endpoint':
  public_url => "https://${::fqdn}:443/main/",
  admin_url  => "https://${::fqdn}:443/admin/",
}

keystone_config { 'ssl/enable': ensure  => absent }

include ::apache
class { '::keystone::wsgi::apache':
  ssl         => true,
  public_port => 443,
  admin_port  => 443,
  public_path => '/main/',
  admin_path  => '/admin/'
}
