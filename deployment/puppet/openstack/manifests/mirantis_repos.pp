#
class openstack::mirantis_repos (
  # DO NOT change this value to 'internal'. all our customers are relying on external repositories
  $type        = 'external',
  $enable_epel = false,
  $disable_puppet_labs_repos = true,

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
          apt::source  { 'precise-fuel-folsom':
          location => 'http://download.mirantis.com/precise-fuel-folsom',
          release => 'precise',
          repos => 'main',
          key => "F8AF89DD",
          key_source => 'http://download.mirantis.com/precise-fuel-folsom/Mirantis.key',
#         key_server => "pgp.mit.edu",
          include_src => false,
          pin       => "1000"
        }
      }
      # Below we set our internal repos for testing purposes. Some of them may match with external ones.
      if $type == 'internal' {
        file {'/etc/apt/sources.list':
          ensure => absent
        }
        File['/etc/apt/sources.list']->Apt::Source<||>
         apt::source  { 'precise-fuel-folsom':
          location => 'http://172.18.67.168/ubuntu-repo/precise-fuel-folsom',
          release => 'precise',
          repos => 'main',
          key => "F8AF89DD",
          key_source => 'http://172.18.67.168/ubuntu-repo/precise-fuel-folsom/Mirantis.key',
#         key_server => "pgp.mit.edu",
          include_src => false,
          pin         => 1000,
        }
        apt::source  { 'cloud-archive':
          location => 'http://172.18.67.168/ubuntu-cloud.archive.canonical.com/ubuntu',
          release => 'precise-updates/folsom',
          repos => 'main',
          key => "5EDB1B62EC4926EA",
          key_source => 'http://172.18.67.168/ubuntu-repo/precise-fuel-folsom/cloud-archive.key',
#         key_server => "pgp.mit.edu",
          include_src => false,
        }
        apt::source  { 'ubuntu-mirror':
          location => 'http://172.18.67.168/ubuntu-repo/mirror.yandex.ru/ubuntu',
          release => 'precise',
          repos => 'main universe multiverse restricted',
        }
         apt::source  { 'ubuntu-updates':
          location => 'http://172.18.67.168/ubuntu-repo/mirror.yandex.ru/ubuntu',
          release => 'precise-updates',
          repos => 'main universe multiverse restricted',
        }
         apt::source  { 'ubuntu-security':
          location => 'http://172.18.67.168/ubuntu-repo/mirror.yandex.ru/ubuntu',
          release => 'precise-updates',
          repos => 'main universe multiverse restricted',
        }
    }

    if !defined(Class['apt::update']) {
     class { 'apt::update': stage => $::openstack::mirantis_repos::stage }
    }

  
#     In no one custom Debian repository is defined, it is necessary to force run apt-get update
#     Please uncomment the following block to order puppet to force apt-get update
################ Start of forced apt-get update block ##############
#        class { 'apt':
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
        key_source => "http://download.mirantis.com/epel-fuel-folsom/epel.key\n  http://download.mirantis.com/epel-fuel-folsom/centos.key\n http://download.mirantis.com/epel-fuel-folsom/rabbit.key\n http://download.mirantis.com/epel-fuel-folsom/mirantis.key\n http://download.mirantis.com/epel-fuel-folsom/mysql.key\n",
        gpgcheck	=> '1'
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

#Puppetlabs repos are really slow. This can slow deployment or even lead to yum timeout.

      if $disable_puppet_labs_repos {
          if defined (Yumrepo['puppetlabs-products']) {yumrepo {'puppetlabs-products': enabled=>0 }}
          if defined (Yumrepo['puppetlabs-deps']) {yumrepo {'puppetlabs-deps': enabled=>0}}
      }

    }
    default: {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }
}
