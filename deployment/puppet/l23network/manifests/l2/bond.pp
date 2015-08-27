# == Define: l23network::l2::bond
#
# Create linux native or Open vSwitch bond port
#
#
# === Parameters
#
# [*name*]
#   Bond name.
#
# [*bridge*]
#   Bridge that will contain this bond. Is only required for OVS bonds
#
# [*interfaces*]
#   List of interfaces in this bond.
#
# [*provider*]
#  This manifest supports lnx or ovs providers

define l23network::l2::bond (
  $ensure                  = present,
  $bond                    = $name,
  $use_ovs                 = $::l23network::use_ovs,
  $interfaces              = undef,
  $bridge                  = undef,
  $mtu                     = undef,
  $onboot                  = undef,
  $delay_while_up          = undef,
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

  $lacp_states = [
    'off',
    'passive',
    'active'
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
    if is_integer($bond_properties[lacp_rate]) and $bond_properties[lacp_rate] < size($lacp_rates) {
      $lacp_rate = $lacp_rates[$bond_properties[lacp_rate]]
    } else {
      # default value by design https://www.kernel.org/doc/Documentation/networking/bonding.txt
      $lacp_rate = pick($bond_properties[lacp_rate], $lacp_rates[0])
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

  if ! $bond_properties[lacp] {
    # default value
    $lacp = $lacp_states[0]
  } else {
    $lacp = $bond_properties[lacp]
  }

  # default bond properties
  $default_bond_properties = {
    mode             => $bond_mode,
    miimon           => $miimon,
    lacp_rate        => $lacp_rate,
    lacp             => $lacp,
    xmit_hash_policy => $xmit_hash_policy
  }

  $real_bond_properties = merge($bond_properties, $default_bond_properties)

  if $interfaces {
    validate_array($interfaces)
  }

  if $delay_while_up and ! is_numeric($delay_while_up) {
    fail("Delay for waiting after UP interface ${port} should be numeric, not an '$delay_while_up'.")
  }

  if ! $bridge and $provider == 'ovs' {
    fail("Bridge is not defined for bond ${bond}. This is necessary for Open vSwitch bonds")
  }

  # Use $monolith_bond_providers list for prevent creating ports for monolith bonds
  $actual_provider_for_bond_interface = $provider ? {
    undef   => default_provider_for('L2_port'),
    default => $provider
  }
  $eee = default_provider_for('L2_port')

  if member($actual_monolith_bond_providers, $actual_provider_for_bond_interface) {
    # just interfaces in UP state should be presented
    l23network::l2::bond_interface{ $interfaces:
      bond                 => $bond,
      bond_is_master       => false,
      mtu                  => $mtu,
      interface_properties => $interface_properties,
      ensure               => $ensure,
    }
  } else {
    l23network::l2::bond_interface{ $interfaces:
      bond                 => $bond,
      mtu                  => $mtu,
      interface_properties => $interface_properties,
      ensure               => $ensure,
      provider             => $actual_provider_for_bond_interface
    }
  }

  if (! defined(L23network::L2::Bridge[$bridge]) and $provider == 'ovs') {
    l23network::l2::bridge { $bridge:
      ensure    => 'present',
      provider  => $provider,
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
      bond_lacp             => $real_bond_properties[lacp],
      bond_lacp_rate        => $real_bond_properties[lacp_rate],
      bond_xmit_hash_policy => $real_bond_properties[xmit_hash_policy],
      delay_while_up        => $delay_while_up,
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

  if $::osfamily =~ /(?i)redhat/ {
    if $delay_while_up {
      file {"${::l23network::params::interfaces_dir}/interface-up-script-${bond}":
        ensure  => present,
        owner   => 'root',
        mode    => '0755',
        content => template("l23network/centos_post_up.erb"),
      } -> L23_stored_config <| title == $bond |>
    } else {
      file {"${::l23network::params::interfaces_dir}/interface-up-script-${bond}":
        ensure  => absent,
      } -> L23_stored_config <| title == $bond |>
    }
  }

}
