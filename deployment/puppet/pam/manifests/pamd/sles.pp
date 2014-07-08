# == Class: pam::pamd::sles
#
class pam::pamd::sles {

  include pam::params

  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644'
  }

  file { "${pam::params::prefix_pamd}/common-account-pc":
    content => template('pam/pam.d/common-account.erb')
  }

  file { "${pam::params::prefix_pamd}/common-auth-pc":
    content => template('pam/pam.d/common-auth.erb')
  }

  file { "${pam::params::prefix_pamd}/common-password-pc":
    content => template('pam/pam.d/common-password.erb')
  }

  file { "${pam::params::prefix_pamd}/common-session-pc":
    content => template('pam/pam.d/common-session.erb')
  }

  if($pam::pamd::pam_ldap) {

    file { '/etc/ldap.conf':
      ensure  => link,
      target  => $pam::params::ldap_conf,
      require => [ Class['ldap'], File[$pam::params::ldap_conf] ],
    }

  }

}

