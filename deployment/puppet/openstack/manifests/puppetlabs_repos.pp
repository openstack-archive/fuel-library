class openstack::puppetlabs_repos (
) {
  case $::osfamily {
    'Debian': {
       apt::source { 'puppetlabs':
         location   => 'http://apt.puppetlabs.com',
         repos      => 'main dependencies',
         key_source =>  'http://apt.puppetlabs.com/pubkey.gpg',
       }

      class { 'apt::update': }

#     In no one custom Debian repository is defined, it is necessary to force run apt-get update 
#     Please uncomment the following block to order puppet to force apt-get update
################ Start of forced apt-get update block ##############
#        class { 'apt':
#          stage => 'openstack-custom-repo',
#          always_apt_update => true,
#        }
################ End of forced apt-get update block ###############
    }
    'RedHat': {
      yumrepo { 'puppet-labs':
        mirrorlist => 'http://yum.puppetlabs.com/el/6/products/x86_64',
        gpgkey         => 'http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs',
        gpgcheck       => 1,
      }

      yumrepo { 'puppet-labs-deps':
              mirrorlist => 'http://yum.puppetlabs.com/el/6/dependencies/x86_64',
              gpgkey         => 'http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs',
              gpgcheck       => 1,
      }

    }
    default: {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }
}