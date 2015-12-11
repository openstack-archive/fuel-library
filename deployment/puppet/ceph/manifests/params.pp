# These are per-OS parameters and should be considered static
class ceph::params {

  #1.2.9 debian package service name is libvirtd
  #http://http.debian.net/debian/pool/main/libv/libvirt/libvirt_1.2.9-9.debian.tar.xz
  $libvirt_service_name           = 'libvirtd'

  case $::osfamily {
    'RedHat': {
      $service_name               = 'ceph'
      $service_nova_compute       = 'openstack-nova-compute'
      #RadosGW
      $service_httpd              = 'httpd'
      $package_httpd              = 'httpd'
      $user_httpd                 = 'apache'
      $package_libnss             = 'nss-tools'
      $service_radosgw            = 'ceph-radosgw'
      $package_radosgw            = 'ceph-radosgw'
      $package_modssl             = 'mod_ssl'
      $package_fastcgi            = 'mod_fastcgi'
      $dir_httpd_conf             = '/etc/httpd/conf/'
      $dir_httpd_sites            = '/etc/httpd/conf.d/'
      $dir_httpd_ssl              = '/etc/httpd/ssl/'
      $dir_httpd_log              = '/var/log/httpd/'

      package { ['ceph', 'redhat-lsb-core','ceph-deploy',]:
        ensure => installed,
      }

      file {'/etc/sudoers.d/ceph':
        content => "# This is required for ceph-deploy\nDefaults !requiretty\n"
      }
    }

    'Debian': {
      $service_name               = 'ceph-all'
      $service_nova_compute       = 'nova-compute'
      #RadosGW
      $service_httpd              = 'apache2'
      $package_httpd              = 'apache2'
      $user_httpd                 = 'www-data'
      $package_libnss             = 'libnss3-tools'
      $service_radosgw            = 'radosgw'
      $package_radosgw            = 'radosgw'
      $package_fastcgi            = 'libapache2-mod-fastcgi'
      $package_modssl             = undef
      $dir_httpd_conf             = '/etc/httpd/conf/'
      $dir_httpd_sites            = '/etc/apache2/sites-available/'
      $dir_httpd_ssl              = '/etc/apache2/ssl/'
      $dir_httpd_log              = '/var/log/apache2/'

      package { ['ceph','ceph-deploy', ]:
        ensure => installed,
      }
    }

    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }
}
