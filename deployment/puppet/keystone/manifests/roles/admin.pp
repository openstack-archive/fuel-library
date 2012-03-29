class keystone::roles::admin(
  $email    = 'demo@puppetlabs.com',
  $password = 'ChangeMe'
) {

  keystone_tenant { 'service':
    ensure      => present,
    enabled     => 'True',
    description => 'Tenant for the openstack services',
  }
  keystone_tenant { 'openstack':
    ensure      => present,
    enabled     => 'True',
    description => 'admin tenant',
  }->
  keystone_user { 'admin':
    ensure      => present,
    enabled     => 'True',
    tenant      => 'openstack',
    email       => $email,
    password    => $password,
  }->
  keystone_role { ['admin', 'Member']:
    ensure => present,
  }->
  keystone_user_role { 'admin@openstack':
    roles  => 'admin',
    ensure => present,
  }
}
