#
class openstack::mirantis_repos (
  # DO NOT change this value to 'defaults'. All our customers are relying on external repositories
  $type         = 'default',
  $originator   = 'Mirantis Product <product@mirantis.com>',
  $disable_puppet_labs_repos = true,
  $upstream_mirror           = true,
  $deb_mirror   = 'http://172.18.67.168/ubuntu-repo/mirror.yandex.ru/ubuntu',
  $deb_updates  = 'http://172.18.67.168/ubuntu-repo/mirror.yandex.ru/ubuntu',
  $deb_security = 'http://172.18.67.168/ubuntu-repo/mirror.yandex.ru/ubuntu',
  $deb_fuel_folsom_repo      = 'http://172.18.67.168/ubuntu-repo/precise-fuel-folsom',
  $deb_fuel_grizzly_repo  = 'http://osci-gbp.srt.mirantis.net/ubuntu/fuel/',
  $deb_cloud_archive_repo    = 'http://172.18.67.168/ubuntu-cloud.archive.canonical.com/ubuntu',
  $deb_rabbit_repo           = 'http://172.18.67.168/ubuntu-repo/precise-fuel-folsom',
  $enable_epel = false,
  $fuel_mirrorlist           = 'http://download.mirantis.com/epel-fuel-folsom-2.1/mirror.internal-stage.list',
  $mirrorlist_base           = 'http://172.18.67.168/centos-repo/mirror-6.3-os.list',
  $mirrorlist_updates        = 'http://172.18.67.168/centos-repo/mirror-6.3-updates.list',
  $grizzly_baseurl           = 'http://download.mirantis.com/epel-fuel-grizzly-3.1',
  $enable_test_repo          = false,
  $repo_proxy   = undef,
  $use_upstream_mysql     = false,
) {
  case $::osfamily {
    'Debian' : {
      class { 'apt::proxy':
        proxy => $repo_proxy,
        stage => $::openstack::mirantis_repos::stage
      }

      apt::pin { 'mirantis-releases':
        order      => 20,
        priority   => 1001,
      }

      if $use_upstream_mysql {
        apt::pin { 'upstream-mysql':
          order    => 19,
          priority => 1002,
          releasecustom  => "v=12.04,o=Ubuntu",
          packages => "/^mysql/"
        }
      }

      Apt::Source <| |> -> Apt::Pin <| |>

      if $type == 'default' {
        apt::source { 'mirantis-releases':
          location    => 'http://download.mirantis.com/precise-grizzly-fuel-3.2',
          release     => 'precise',
          repos       => 'main',
          key         => '3E301371',
          key_source  => 'http://download.mirantis.com/precise-grizzly-fuel-3.2/Mirantis.key',
          include_src => false,
        }
      }

      # Below we set our internal repos for testing purposes. Some of them may match with external ones.
      if $type == 'custom' {
        apt::pin { 'mirantis-releases':
          order      => 19,
          priority   => 1001,
        }

        apt::source { 'mirantis-releases':
          location    => 'http://172.18.67.168/ubuntu-repo/precise-grizzly-fuel-3.2',
          release     => 'precise',
          repos       => 'main',
          key         => '3E301371',
          key_source  => 'http://172.18.67.168/ubuntu-repo/precise-grizzly-fuel-3.2/Mirantis.key',
          include_src => false,
        }

        if $upstream_mirror == true {
          file { '/etc/apt/sources.list': ensure => absent }
          File['/etc/apt/sources.list'] -> Apt::Source <| |>

          apt::source { 'ubuntu-mirror':
            location => $deb_mirror,
            release  => 'precise',
            repos    => 'main universe multiverse restricted',
          }

          apt::source { 'ubuntu-updates':
            location => $deb_updates,
            release  => 'precise-updates',
            repos    => 'main universe multiverse restricted',
          }

          apt::source { 'ubuntu-security':
            location => $deb_security,
            release  => 'precise-security',
            repos    => 'main universe multiverse restricted',
          }
        }
      }

      if !defined(Class['apt::update']) {
        class { 'apt::update': stage => $::openstack::mirantis_repos::stage }
      }

      #     In no one custom Debian repository is defined, it is necessary to force run apt-get update
      #     Please uncomment the following block to order puppet to force apt-get update
      # ############### Start of forced apt-get update block ##############
      #        class { 'apt':
      #          always_apt_update => true,
      #        }
      # ############### End of forced apt-get update block ###############
    }

    'RedHat': {

      Yumrepo {
        proxy   => $repo_proxy,
      }

      # added internal (custom)/external (default) network mirror
      if $type == 'default' {

        yumrepo { 'centos-base':
            descr      => 'Mirantis-CentOS-Base',
            name       => 'base',
            baseurl    => 'http://download.mirantis.com/centos-6.4',
            gpgcheck   => '1',
            gpgkey     => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
            mirrorlist => absent,
        }

        yumrepo { 'openstack-epel-fuel-grizzly':
            descr      => 'Mirantis OpenStack grizzly Custom Packages',
            baseurl    => 'http://download.mirantis.com/epel-fuel-grizzly-3.1',
            gpgcheck   => '1',
            gpgkey     => 'http://download.mirantis.com/epel-fuel-grizzly-3.1/mirantis.key',
            mirrorlist => absent,
        }
        
      # completely disable additional out-of-box repos
        yumrepo { 'extras':
                descr => 'CentOS-$releasever - Extras',
                mirrorlist => 'http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras',
                gpgcheck => '1',
                baseurl => absent,
                gpgkey => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
                enabled => '0',
        }

        yumrepo { 'updates':
                descr => 'CentOS-$releasever - Updates',
                mirrorlist => 'http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates',
                gpgcheck => '1',
                baseurl => absent,
                gpgkey => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
                enabled => '0',
        }
      }

      if $type == 'custom' {

        yumrepo { 'openstack-epel-fuel-grizzly':
          descr      => 'Mirantis OpenStack grizzly Custom Packages',
          baseurl    => 'http://download.mirantis.com/epel-fuel-grizzly-3.1',
          gpgcheck   => '0',
        }

        if $upstream_mirror == true {
          yumrepo { 'centos-base':
            name       => 'base',
            gpgcheck   => '1',
            mirrorlist => $mirrorlist_base,
            gpgkey    => 'http://centos.srt.mirantis.net/RPM-GPG-KEY-CentOS-6',
          }

          yumrepo { 'centos-updates':
            name       => 'updates',
            gpgcheck   => '1',
            mirrorlist => $mirrorlist_updates,
            gpgkey    => 'http://centos.srt.mirantis.net/RPM-GPG-KEY-CentOS-6',
          }
        }
      }

      if $enable_epel {
        Yumrepo {
          failovermethod => 'priority',
          gpgkey         => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
          gpgcheck       => 1,
          enabled        => 1,
        }
        yumrepo { 'epel-testing':
          descr      => 'Extra Packages for Enterprise Linux 6 - Testing - $basearch',
          mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=testing-epel6&arch=$basearch',
          enabled    => 1,
        }

        yumrepo { 'epel':
          descr      => 'Extra Packages for Enterprise Linux 6 - $basearch',
          mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        }
      }

      # Puppetlabs repos are really slow. This can slow deployment or even lead to yum timeout.

      if $disable_puppet_labs_repos {
        if defined(Yumrepo['puppetlabs-products']) {
          yumrepo { 'puppetlabs-products': enabled => 0 }
        }

        if defined(Yumrepo['puppetlabs-deps']) {
          yumrepo { 'puppetlabs-deps': enabled => 0 }
        }
      }

      exec { 'yum_make_safe_cache': command => "/usr/bin/yum clean all", }
      Yumrepo <| |> -> Exec['yum_make_safe_cache']
    }
    default  : {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }
}


