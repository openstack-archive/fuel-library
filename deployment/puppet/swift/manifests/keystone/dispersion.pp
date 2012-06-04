class swift::keystone::dispersion(
  $auth_user = 'dispersion',
  $auth_pass = 'dispersion_password'
) {

  keystone_user { $auth_user:
    ensure   => present,
    password => $auth_pass,
  }

  keystone_user_role { "${auth_user}@services":
    ensure  => present,
    roles   => 'admin',
    require => Keystone_user[$auth_user]
  }
}
