#
class openstack::mirantis_repos (
  # DO NOT change this value to 'internal'. all our customers are relying on external repositories
  $type        = 'external',
  $enable_epel = false

) {
  case $::osfamily {
    'Debian': {
      if $type == 'external' {
        apt::source  { 'cloud-archive':
          location => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
          release => 'precise-updates/folsom',
          repos => 'main',
          key => "5EDB1B62EC4926EA",
          key_source => 'http://download.mirantis.com/precise-fuel-folsom/cloud-archive.key',
#          key_server => "keys.gnupg.net",
          include_src => false,
        }
      }
      # Below we set our internal repos for testing purposes. Some of them may match with external ones.
      if $type == 'internal' {
        apt::source  { 'cloud-archive':
          location => 'http://172.18.67.168/ubuntu-cloud.archive.canonical.com/ubuntu',
          release => 'precise-updates/folsom',
          repos => 'main',
          key => "5EDB1B62EC4926EA",
          key_source => 'http://172.18.67.168/ubuntu-repo/precise-fuel-folsom/cloud-archive.key',
#         key_server => "pgp.mit.edu",
          include_src => false,
        }
#        apt::source  { 'mirantis-internal-test-repo':
#          key => '420851BC',
#          location => 'http://172.18.66.213/deb',
#          key_source => 'http://172.18.66.213/gpg.pub',
#          origin => '172.18.66.213',
#        }
    }
  
  class { 'apt::update': stage => 'openstack-custom-repo' }
  
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
      #added internal/external network mirror
      $mirrorlist="http://download.mirantis.com/epel-fuel-folsom/mirror.${type}.list"

      class { 'openstack::repo::yum':
        descr      => 'Mirantis OpenStack Custom Packages',
        repo_name  => 'openstack-epel-fuel',
        mirrorlist => $mirrorlist,
        key_source => "https://fedoraproject.org/static/0608B895.txt\n  http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-6\n http://download.mirantis.com/epel-fuel-folsom/rabbit.key\n http://download.mirantis.com/epel-fuel-folsom/mirantis.key",
        stage      => 'openstack-custom-repo',
        gpgcheck	=> '0'
      }

      if $enable_epel {
        Yumrepo {
          failovermethod => 'priority',
          gpgkey         => 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6',
          gpgcheck       => 1,
          enabled        => 1,
        }

        yumrepo { 'epel-testing':
          descr      => 'Extra Packages for Enterprise Linux 6 - Testing - $basearch',
          mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=testing-epel6&arch=$basearch',
        }

        yumrepo { 'epel':
          descr      => 'Extra Packages for Enterprise Linux 6 - $basearch',
          mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        }
      }

    }
    default: {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }
}
