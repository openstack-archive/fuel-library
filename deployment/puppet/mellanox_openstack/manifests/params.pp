class mellanox_openstack::params {

  $eswitchd_package          = 'eswitchd'

  case $::osfamily {
    'RedHat': {
      $neutron_mlnx_packages = ['openstack-neutron-mellanox']
      $mlnxvif_package       = 'mlnxvif'
    }
    'Debian': {
      $neutron_mlnx_packages = ['neutron-plugin-mlnx','neutron-plugin-mlnx-agent']
      $mlnxvif_package       = 'python-mlnxvif'
    }
  }

}
