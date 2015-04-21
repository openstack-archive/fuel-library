# == Define: l23network::l2::bond
#
# Create open vSwitch port bonding and add to the OVS bridge.
#
# === Parameters
#
# [*name*]
#   Bond name.
#
# [*bridge*]
#   Bridge that will contain this bond.
#
# [*interfaces*]
#   List of interfaces in this bond.

define l23network::l2::bond (
  $ensure                  = present,
  $bond                    = $name,
  $use_ovs                 = $::l23network::use_ovs,
  $interfaces              = undef,
  $bridge                  = undef,
  $mtu                     = undef,
  $onboot                  = undef,
# $ethtool                 = undef,
  $bond_properties         = undef,  # bond configuration options
  $interface_properties    = undef,  # configuration options for included interfaces (mtu, ethtool, etc...)
  $vendor_specific         = undef,
  $monolith_bond_providers = undef,
  $provider                = undef,
  # deprecated parameters, in the future ones will be moved to the vendor_specific hash
# $skip_existing           = undef,
) {
  include ::stdlib
  include ::l23network::params

  $actual_monolith_bond_providers = $monolith_bond_providers ? {
    undef   => $l23network::params::monolith_bond_providers,
    default => $monolith_bond_providers,
  }

  $bond_modes = [
    'balance-rr',
    'active-backup',
    'balance-xor',
    'broadcast',
    '802.3ad',
    'balance-tlb',
    'balance-alb'
  ]

  $lacp_rates = [
    'slow',
    'fast'
  ]

  $xmit_hash_policies = [
    'layer2',
    'layer2+3',
    'layer3+4',
    'encap2+3',
    'encap3+4'
  ]

  # calculate string representation for bond_mode
  if ! $bond_properties[mode] {
    # default value by design https://www.kernel.org/doc/Documentation/networking/bonding.txt
    $bond_mode = $bond_modes[0]
  } elsif is_integer($bond_properties[mode]) and $bond_properties[mode] < size($bond_modes) {
    $bond_mode = $bond_modes[$bond_properties[mode]]
  } else {
    $bond_mode = $bond_properties[mode]
  }

  # calculate string representation for lacp_rate
  if $bond_mode == '802.3ad' {
    if ! $bond_properties[lacp_rate] {
      # default value by design https://www.kernel.org/doc/Documentation/networking/bonding.txt
      $lacp_rate = $lacp_rates[0]
    } elsif is_integer($bond_properties[lacp_rate]) and $bond_properties[lacp_rate] < size($lacp_rates) {
      $lacp_rate = $lacp_rates[$bond_properties[lacp_rate]]
    } else {
      $lacp_rate = $bond_properties[lacp_rate]
    }
  }

  # calculate default miimon
  if is_integer($bond_properties[miimon]) and $bond_properties[miimon] >= 0 {
    $miimon = $bond_properties[miimon]
  } else {
    # recommended default value https://www.kernel.org/doc/Documentation/networking/bonding.txt
    $miimon = 100
  }

  # calculate string representation for xmit_hash_policy
  if ( $bond_mode == '802.3ad' or $bond_mode == 'balance-xor' or $bond_mode == 'balance-tlb') {
    if ! $bond_properties[xmit_hash_policy] {
      # default value by design https://www.kernel.org/doc/Documentation/networking/bonding.txt
      $xmit_hash_policy = $xmit_hash_policies[0]
    } else {
      $xmit_hash_policy = $bond_properties[xmit_hash_policy]
    }
  }

  # default bond properties
  $default_bond_properties = {
    mode             => $bond_mode,
    miimon           => $miimon,
    lacp_rate        => $lacp_rate,
    xmit_hash_policy => $xmit_hash_policy
  }

  $real_bond_properties = merge($bond_properties, $default_bond_properties)

  if $interfaces {
    validate_array($interfaces)
  }

  # Use $monolith_bond_providers list for prevent creating ports for monolith bonds
  $actual_provider_for_bond_interface = $provider ? {
    undef   => default_provider_for('L2_port'),
    default => $provider
  }
  $eee = default_provider_for('L2_port')

  if ! member($actual_monolith_bond_providers, $actual_provider_for_bond_interface) {
    l23network::l2::bond_interface{ $interfaces:
      bond                 => $bond,
      mtu                  => $mtu,
      interface_properties => $interface_properties,
      ensure               => $ensure,
      provider             => $actual_provider_for_bond_interface
    }
  }

  if ! defined(L2_bond[$bond]) {
    if $provider {
      $config_provider = "${provider}_${::l23_os}"
    } else {
      $config_provider = undef
    }

    if ! defined(L23_stored_config[$bond]) {
      l23_stored_config { $bond: }
    }
    L23_stored_config <| title == $bond |> {
      ensure                => $ensure,
      if_type               => 'bond',
      bridge                => $bridge,
      mtu                   => $mtu,
      onboot                => $onboot,
      bond_mode             => $real_bond_properties[mode],
      bond_master           => undef,
      bond_slaves           => $interfaces,
      bond_miimon           => $real_bond_properties[miimon],
      bond_lacp_rate        => $real_bond_properties[lacp_rate],
      bond_xmit_hash_policy => $real_bond_properties[xmit_hash_policy],
      vendor_specific       => $vendor_specific,
      provider              => $config_provider
    }

    l2_bond { $bond :
      ensure               => $ensure,
      bridge               => $bridge,
      use_ovs              => $use_ovs,
      onboot               => $onboot,
      slaves               => $interfaces,
      mtu                  => $mtu,
      interface_properties => $interface_properties,
      bond_properties      => $real_bond_properties,
      vendor_specific      => $vendor_specific,
      provider             => $provider
    }

    # this need for creating L2_port resource by ifup, if it allowed by OS
    L23_stored_config[$bond] -> L2_bond[$bond]

    Anchor['l23network::init'] -> K_mod<||> -> L2_bond<||>

  }

}
