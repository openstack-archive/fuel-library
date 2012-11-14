#
class openstack::mirantis_repos (
  $type        = 'external',
  $enable_epel = false
) {
  case $::osfamily {
    'Debian': {
      class { 'apt':
        stage => 'openstack-ci-repo'
      }->
      class { 'openstack::repo::apt':
        key => '420851BC',
        location => 'http://172.18.66.213/deb',
        key_source => 'http://172.18.66.213/gpg.pub',
        origin => '172.18.66.213',
        stage => 'openstack-ci-repo'
      }
    }
    'RedHat': {
      #$repo_baseurl='http://download.mirantis.com/epel-fuel-folsom'

      #added internal/external network mirror
      $mirrorlist="http://download.mirantis.com/epel-fuel-folsom/mirror.${type}.list"

      class { 'openstack::repo::yum':
        descr      => 'Mirantis OpenStack Custom Packages',
        repo_name  => 'openstack-epel-fuel',
        #      location   => $repo_baseurl,
        mirrorlist => $mirrorlist,
        key_source => "https://fedoraproject.org/static/0608B895.txt\n  http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-6\n http://download.mirantis.com/epel-fuel-folsom/rabbit.key",
        stage      => 'openstack-custom-repo',
        gpgcheck	=> '0'
      }

      if $enable_epel {
        yumrepo { 'epel-testing':
          descr          => 'Extra Packages for Enterprise Linux 6 - Testing - $basearch',
          mirrorlist     => 'https://mirrors.fedoraproject.org/metalink?repo=testing-epel6&arch=$basearch',
          failovermethod => 'priority',
          gpgkey         => 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6',
          gpgcheck       => 1,
          enabled        => 1,
        }
      }

    }
    default: {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }
}
