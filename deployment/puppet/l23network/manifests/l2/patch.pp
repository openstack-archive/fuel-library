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
  # We can't create more then one patch between the same bridges.
  $bridge1_provider = get_provider_for('L2_bridge', $bridges[0])
  $bridge2_provider = get_provider_for('L2_bridge', $bridges[1])

  if $bridge1_provider == 'ovs' and $bridge2_provider == 'ovs' {
    $act_bridges  = sort($bridges)
    $ovs2ovs = true
    if $vlan_ids == undef {
      $act_vlan_ids = [0,0]
    } elsif $act_bridges == $bridges {
      $act_vlan_ids = $vlan_ids
    } else {
      $act_vlan_ids = [$vlan_ids[1], $vlan_ids[0]]
    }
  } elsif $bridge1_provider == 'ovs' and $bridge2_provider == 'lnx' {
    $act_bridges  = [$bridges[0], $bridges[1]]
    $act_vlan_ids = undef
  } elsif $bridge1_provider == 'lnx' and $bridge2_provider == 'ovs' {
    $act_bridges  = [$bridges[1], $bridges[0]]
    $act_vlan_ids = undef
  } else {
    $lnx2lnx = true
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

    if $ovs2ovs {
      if ! defined(L23_stored_config[$patch_jacks_names[0]]) {
        l23_stored_config { $patch_jacks_names[0]: }
      }
      L23_stored_config <| title == $patch_jacks_names[0] |> {
        ensure          => $ensure,
        if_type         => 'patch',
        bridge          => $act_bridges[0],
        vlan_id         => $act_vlan_ids[0],
        jacks           => $patch_jacks_names[1],
        onboot          => true,
        vendor_specific => $vendor_specific,
        provider        => $config_provider
      }
      L23_stored_config[$patch_jacks_names[0]] -> L2_patch[$patch_name]

      if ! defined(L23_stored_config[$patch_jacks_names[1]]) {
        l23_stored_config { $patch_jacks_names[1]: }
      }
      L23_stored_config <| title == $patch_jacks_names[1] |> {
        ensure          => $ensure,
        if_type         => 'patch',
        bridge          => $act_bridges[1],
        vlan_id         => $act_vlan_ids[1],
        jacks           => $patch_jacks_names[0],
        onboot          => true,
        vendor_specific => $vendor_specific,
        provider        => $config_provider
      }
      L23_stored_config[$patch_jacks_names[1]] -> L2_patch[$patch_name]
    } elsif $lnx2lnx {
      if ! defined(L23_stored_config[$patch_jacks_names[0]]) {
        l23_stored_config { $patch_jacks_names[0]: }
      }
      L23_stored_config <| title == $patch_jacks_names[0] |> {
        ensure          => $ensure,
        if_type         => 'patch',
        bridge          => $act_bridges[0],
        jacks           => $patch_jacks_names,
        onboot          => true,
        vendor_specific => $vendor_specific,
        provider        => $config_provider
      }
      L23_stored_config[$patch_jacks_names[0]] -> L2_patch[$patch_name]

      if ! defined(L23_stored_config[$patch_jacks_names[1]]) {
        l23_stored_config { $patch_jacks_names[1]: }
      }
      L23_stored_config <| title == $patch_jacks_names[1] |> {
        ensure          => $ensure,
        if_type         => 'patch',
        bridge          => $act_bridges[1],
        jacks           => $patch_jacks_names,
        onboot          => true,
        vendor_specific => $vendor_specific,
        provider        => $config_provider
      }
      L23_stored_config[$patch_jacks_names[1]] -> L2_patch[$patch_name]
    } else {
      # ovs2lnx patch
      if ! defined(L23_stored_config[$patch_jacks_names[0]]) {
        # we use only one (first) patch jack name here and later,
        # because a both jacks for patch are created by
        # one command. This command stores in one config file.
        l23_stored_config { $patch_jacks_names[0]: }
      }
      L23_stored_config <| title == $patch_jacks_names[0] |> {
        ensure          => $ensure,
        if_type         => 'vport',
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
      vlan_ids        => $act_vlan_ids,
      mtu             => $mtu,
      vendor_specific => $vendor_specific,
      provider        => $provider
    }

    Anchor['l23network::init'] -> K_mod<||> -> L2_patch<||>
  }
}
# vim: set ts=2 sw=2 et :
