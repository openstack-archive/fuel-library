import 'common/globals.pp'

if $use_vmware_nsx {
  class { 'plugin_neutronnsx':
    neutron_config     => $neutron_config,
    neutron_nsx_config => $neutron_nsx_config,
    roles              => $roles,
  }
}
