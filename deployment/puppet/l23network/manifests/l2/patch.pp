# == Define: l23network::l2::patch
#
# Connect two open vSwitch bridges by virtual patch-cord.
#
# === Parameters
# [*bridges*]
#   Bridges that will be connected.
#
# [*peers*]
#   Patch port names for both bridges. must be array of two strings.
#
# [*vlan_ids*]
#   Specify 802.1q tag for each end of patchcord. Must be array of 2 integers.
#   Default [0,0] -- untagged
#
# [*trunks*]
#   Specify array of 802.1q tags (identical for both ends) if need configure patch in trunk mode.
#   Define trunks => [0] if you need pass only untagged traffic.
#   by default -- undefined.
#
# [*skip_existing*]
#   If this patch already exists it will be ignored without any errors.
#   Must be true or false.
#
define l23network::l2::patch (
  $bridges,
  $ensure          = present,
  $peers           = [undef,undef],  # unused and will be
  $vlan_ids        = [0, 0],         # deprecated or moved
  $trunks          = [],             # to the 'vendor_specific' hash
  $vendor_specific = undef,
  $provider        = undef,
) {

  #$provider_1 = get_provider_for('L2_bridge', bridges[0])  # this didn't work, because parser functions
  #$provider_2 = get_provider_for('L2_bridge', bridges[1])  # executed before resources prefetch

  # Architecture limitation.
  # We can't create more one patch between same bridges.
  $patch_name = get_patch_name($bridges)

  if ! defined(L2_patch[$patch_name]) {
    if $provider {
      $config_provider = "${provider}_${::l23_os}"
    } else {
      $config_provider = undef
    }

    if ! defined(L23_stored_config[$patch_name]) {
      l23_stored_config { $patch_name: }
    }
    # L23_stored_config <| title == $patch_name |> {
    #   ensure          => $ensure,
    #   if_type         => 'ethernet',
    #   bridge          => $bridge,
    #   vlan_id         => $port_vlan_id,
    #   vlan_dev        => $port_vlan_dev,
    #   vlan_mode       => $port_vlan_mode,
    #   bond_master     => $master,
    #   mtu             => $mtu,
    #   onboot          => $onboot,
    #   #ethtool              => $ethtool,
    #   #vendor_specific=> $vendor_specific,
    #   provider        => $config_provider
    # }

    l2_patch{ $patch_name :
      ensure               => $ensure,
      bridges              => $bridges,
#     mtu                  => $mtu,
      vendor_specific      => $vendor_specific,
      provider             => $provider
    }

    # this need for creating L2_patch resource by ifup, if it allowed by OS
    #L23_stored_config[$patch1_name] -> L2_patch[$patch_name]
    #L23_stored_config[$patch2_name] -> L2_patch[$patch_name]

    K_mod<||> -> L2_patch<||>
  }
}
# vim: set ts=2 sw=2 et :