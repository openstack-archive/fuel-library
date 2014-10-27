class neutron::plugins::ml2_plugin (
  $neutron_config       = {},
) {
  anchor {'neutron-plugin-ml2': }

  Anchor['neutron-plugin-ml2'] -> Class['neutron::plugins::ml2']
  class {'neutron::plugins::ml2':
      type_drivers          => split($neutron_config[L2][type_drivers], ','),
      tenant_network_types  => split($neutron_config[L2][tenant_network_types], ','),
      mechanism_drivers     => split($neutron_config[L2][mechanism_drivers], ','),
      flat_networks         => split($neutron_config[L2][flat_networks], ','),
      network_vlan_ranges   => split($neutron_config[L2][network_vlan_ranges], ','),
      tunnel_id_ranges      => split($neutron_config[L2][tunnel_id_ranges], ','),
      vxlan_group           => $neutron_config[L2][vxlan_group],
      vni_ranges            => split($neutron_config[L2][vni_ranges], ',')
  }
  Class['neutron::plugins::ml2'] -> Anchor['neutron-plugin-ml2-done']
  Neutron_plugin_ml2<||> -> Anchor['neutron-plugin-ml2-done']

  anchor {'neutron-plugin-ml2-done': }
}