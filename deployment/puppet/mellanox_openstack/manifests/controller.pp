class mellanox_openstack::controller (
  $eswitch_vnic_type            = 'hostdev',
  $eswitch_apply_profile_patch  = 'True',
) {

  neutron_plugin_ml2 {
    'eswitch/vnic_type':            value => $eswitch_vnic_type;
    'eswitch/apply_profile_patch':  value => $eswitch_apply_profile_patch;
  }

}
