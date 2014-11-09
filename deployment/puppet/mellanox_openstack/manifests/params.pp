class mellanox_openstack::params {

  $eswitchd_package          = 'eswitchd'
  $filters_dir               = '/etc/nova/rootwrap.d'
  $filters_file              = "${filters_dir}/network.filters"
  $mlnx_agent_conf           = '/etc/neutron/plugins/mlnx/mlnx_conf.ini'

  case $::osfamily {
    'RedHat': {
      $neutron_mlnx_packages = ['openstack-neutron-mellanox']
      $mlnxvif_package       = 'mlnxvif'
      $agent_service         = 'neutron-mlnx-agent'
      $compute_service_name  = 'openstack-nova-compute'
    }
    'Debian': {
      $neutron_mlnx_packages = ['neutron-plugin-mlnx','neutron-plugin-mlnx-agent']
      $mlnxvif_package       = 'python-mlnxvif'
      $agent_service         = 'neutron-plugin-mlnx-agent'
      $compute_service_name  = 'nova-compute'
    }
  }

}
