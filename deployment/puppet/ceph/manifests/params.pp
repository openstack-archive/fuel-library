# These are per-OS parameters and should be considered static
class ceph::params {

  case $::osfamily {
    'RedHat': {
      $service_cinder_volume      = 'openstack-cinder-volume'
      $service_cinder_volume_opts = '/etc/sysconfig/openstack-cinder-volume'
      $service_glance_api         = 'openstack-glance-api'
      $service_glance_registry    = 'openstack-glance-registry'
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

      package { ['ceph', 'redhat-lsb-core','ceph-deploy', 'pushy',]:
        ensure => latest,
      }

      file {'/etc/sudoers.d/ceph':
        content => "# This is required for ceph-deploy\nDefaults !requiretty\n"
      }
    }

    'Debian': {
      $service_cinder_volume      = 'cinder-volume'
      $service_cinder_volume_opts = '/etc/init/cinder-volume.conf'
      $servic_glance_api          = 'glance-api'
      $service_glance_registry    = 'glance-registry'
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

      package { ['ceph','ceph-deploy', 'python-pushy', ]:
        ensure => latest,
      }
    }

    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }
}
