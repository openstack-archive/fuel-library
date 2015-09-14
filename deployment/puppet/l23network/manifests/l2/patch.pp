# == Define: l23network::l2::patch
#
# Connect two open vSwitch bridges by virtual patch-cord.
#
# === Parameters
# [*bridges*]
#   Bridges that will be connected.
#
# [*mtu*]
#   Specify MTU value for patchcord.
#
# [*vlan_ids*]
#   Specify 802.1q tag for each end of patchcord. Must be array of 2 integers.
#   Default [0,0] -- untagged
#
define l23network::l2::patch (
  $bridges,
  $use_ovs         = $::l23network::use_ovs,
  $ensure          = present,
  $mtu             = undef,
  $vlan_ids        = undef,
  $vendor_specific = undef,
  $provider        = undef,
) {

  include ::stdlib
  include ::l23network::params

  # Architecture limitation.
  # We can't create more one patch between same bridges.
  $provider_1 = get_provider_for('L2_bridge', $bridges[0])
  $provider_2 = get_provider_for('L2_bridge', $bridges[1])

  if $provider_1 == 'ovs' and $provider_2 == 'ovs' {
    $act_bridges = sort($bridges)
    $do_not_create_stored_config = true
  } elsif $provider_1 == 'ovs' and $provider_2 == 'lnx' {
    $act_bridges = [$bridges[0], $bridges[1]]
  } elsif $provider_1 == 'lnx' and $provider_2 == 'ovs' {
    $act_bridges = [$bridges[1], $bridges[0]]
  } else {
    $act_bridges = $bridges
  }

  $patch_name = get_patch_name($act_bridges)
  $patch_jacks_names = get_pair_of_jack_names($act_bridges)

  if ! defined(L2_patch[$patch_name]) {
    if $provider {
      $config_provider = "${provider}_${::l23_os}"
    } else {
      $config_provider = undef
    }

    if ! $do_not_create_stored_config {
      # we shouldn't create any configs for ovs2ovs patchcords, because
      # nor Cantos-5 nor Ubuntu with OVS < 2.4 support create patch resources
      # from network config files. But OVSDB stores patch configuration.
      if ! defined(L23_stored_config[$patch_jacks_names[0]]) {
        # we use only one (last) patch jack name here and later,
        # because a both jacks for patch
        # creates by one command. This command stores in one config file.
        l23_stored_config { $patch_jacks_names[0]: }
      }
      L23_stored_config <| title == $patch_jacks_names[0] |> {
        ensure          => $ensure,
        if_type         => 'ethernet',
        bridge          => $act_bridges,
        jacks           => $patch_jacks_names,
        mtu             => $mtu,
        onboot          => true,
        vendor_specific => $vendor_specific,
        provider        => $config_provider
      }
      L23_stored_config[$patch_jacks_names[0]] -> L2_patch[$patch_name]
    }

    l2_patch{ $patch_name :
      ensure          => $ensure,
      bridges         => $act_bridges,
      use_ovs         => $use_ovs,
      jacks           => $patch_jacks_names,
      vlan_ids        => $vlan_ids,
      mtu             => $mtu,
      vendor_specific => $vendor_specific,
      provider        => $provider
    }

    Anchor['l23network::init'] -> K_mod<||> -> L2_patch<||>
  }
}
# vim: set ts=2 sw=2 et :