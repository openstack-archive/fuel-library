class mellanox_openstack::controller ($ml2_eswitch) {

  neutron_plugin_ml2 {
    'eswitch/vnic_type':            value => $ml2_eswitch['vnic_type'];
    'eswitch/apply_profile_patch':  value => $ml2_eswitch['apply_profile_patch'];
  }

}
