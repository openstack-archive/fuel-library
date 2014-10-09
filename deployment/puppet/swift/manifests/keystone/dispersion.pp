# == Class: swift::keystone::dispersion
#
# This class creates a user in Keystone for the swift-dispersion-report
# and swift-dispersion-populate tools.
#
# The user is given the admin role in the services tenant.
#
# Use the class swift::dispersion to create the matching config file.
#
# === Parameters
#
# [*auth_user*]
#  String. The name of the user.
#  Optional. Defaults to 'dispersion'.
#
# [*auth_pass*]
#  String. The user's password.
#  Optional. Defaults to 'dispersion_password'.
#
# === Authors
#
# François Charlier fcharlier@ploup.net
#

class swift::keystone::dispersion(
  $auth_user = 'dispersion',
  $auth_pass = 'dispersion_password',
  $email     = 'swift@localhost',
  $tenant    = 'services'
) {

  keystone_user { $auth_user:
    ensure   => present,
    password => $auth_pass,
    email    => $email,
    tenant   => $tenant,
  }

  keystone_user_role { "${auth_user}@${tenant}":
    ensure  => present,
    roles   => 'admin',
    require => Keystone_user[$auth_user]
  }
}
