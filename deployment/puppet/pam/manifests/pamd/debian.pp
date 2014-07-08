# == Class: pam::pamd::debian
#
class pam::pamd::debian {

  include pam::params

  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644'
  }

  file { "${pam::params::prefix_pamd}/common-account":
    content => template('pam/pam.d/common-account.erb')
  }

  file { "${pam::params::prefix_pamd}/common-auth":
    content => template('pam/pam.d/common-auth.erb')
  }

  file { "${pam::params::prefix_pamd}/common-password":
    content => template('pam/pam.d/common-password.erb')
  }

  file { "${pam::params::prefix_pamd}/common-session":
    content => template('pam/pam.d/common-session.erb')
  }

  file { "${pam::params::prefix_pamd}/common-session-noninteractive":
    content => template('pam/pam.d/common-session-noninteractive.erb')
  }

  if($pam::pamd::pam_ldap) {

    #Class['ldap'] -> Class['pam::pamd::debian']

    file { '/etc/pam_ldap.conf':
      ensure  => link,
      target  => $pam::params::ldap_conf,
      require => [ Class['ldap'], File[$pam::params::ldap_conf] ],
    }

  }

}

