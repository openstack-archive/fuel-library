class murano::keystone (
  $user     = 'murano',
  $password = 'swordfish',
  $tenant   = 'services',
  $email    = 'murano@mirantis.com'
) {

  keystone_user { $user:
    ensure      => present,
    enabled     => true,
    tenant      => $tenant,
    email       => $email,
    password    => $password,
  }

  keystone_user_role { "${user}@${tenant}":
    roles  => 'admin',
    ensure => present,
  }

}
