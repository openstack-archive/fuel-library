# == Define: l23network::l2::port
#
# Create open vSwitch port and add to the OVS bridge.
#
# === Parameters
#
# [*name*]
#   Port name.
#
# [*bridge*]
#   Bridge that will contain this port.
#
# [*type*]
#   Port type can be set to one of the following values:
#   'system', 'internal', 'tap', 'gre', 'ipsec_gre', 'capwap', 'patch', 'null'.
#   If you do not define of leave this value empty then ovs-vsctl will create
#   the port with default behavior.
#   (see http://openvswitch.org/cgi-bin/ovsman.cgi?page=utilities%2Fovs-vsctl.8)
#
# [*vlan_id*]
#   Specify 802.1q tag for result bond. If need.
#
# [*trunks*]
#   Specify array of 802.1q tags if need configure bond in trunk mode.
#   Define trunks => [0] if you need pass only untagged traffic.
#
# [*skip_existing*]
#   If this port already exists it will be ignored without any errors.
#   Must be true or false.
#
define l23network::l2::port (
  $ensure                = present,
  $use_ovs               = $::l23network::use_ovs,
  $port                  = $name,
  $if_type               = undef,
  $bridge                = undef,
  $onboot                = undef,
  $vlan_id               = undef,  # actually only for OVS workflow
  $vlan_dev              = undef,
  $mtu                   = undef,
  $ethtool               = undef,
  $delay_while_up        = undef,
  $master                = undef,  # used for bonds automatically
  $slave                 = undef,  # used for bonds automatically
# $type                  = undef,  # was '',
  $vendor_specific       = undef,
  $provider              = undef,
  # deprecated parameters, in the future ones will be moved to the vendor_specific hash
# $skip_existing         = undef,
# $port_properties       = [],
# $interface_properties  = [],
# $trunks                = [],
) {

  include ::stdlib
  include ::l23network::params

  # Detect VLAN mode configuration
  case $port {
    /^vlan(\d+)/: {
      $port_name = $port
      $port_vlan_mode = 'vlan'
      if $vlan_id {
        $port_vlan_id = $vlan_id
      } else {
        $port_vlan_id = $1
      }
      if $vlan_dev {
        $port_vlan_dev = $vlan_dev
      } else {
        if $provider != 'ovs' {
          fail("Can't configure vlan interface ${port} without definition vlandev=>ethXX.")
        }
      }
    }
    /^([\w\-]+\d+)\.(\d+)/: {
      if $vlan_dev == false {
        # special case for non-vlan devices witn naming like "aaaNNN.XXX"
        $port_vlan_mode = undef
        $port_vlan_id   = undef
        $port_vlan_dev  = undef
        $port_name      = $port
      } else {
        $port_vlan_mode = 'eth'
        $port_vlan_id   = $2
        $port_vlan_dev  = $1
        $port_name      = "${1}.${2}"
      }
    }
    default: {
      $port_vlan_mode = undef
      $port_vlan_id   = undef
      $port_vlan_dev  = undef
      $port_name      = $port
    }
  }

  if $delay_while_up and ! is_numeric($delay_while_up) {
    fail("Delay for waiting after UP interface ${port} should be numeric, not an '$delay_while_up'.")
  }

  # # implicitly create bridge, if it given and not exists
  # if $bridge {
  #   if !defined(L2_bridge[$bridge]) {
  #     l2_bridge { $bridge: }
  #   }
  #   # or do this from autorequire ??????
  #   L2_bridge[$bridge] -> L2_port[$port_name]
  # }

  if ! defined(L2_port[$port_name]) {
    if $provider {
      $config_provider = "${provider}_${::l23_os}"
    } else {
      $config_provider = undef
    }

    if ! defined(L23_stored_config[$port_name]) {
      l23_stored_config { $port_name: }
    }
    # if_type is not used on debian based distros at all
    # on redhat based - is not strictly required. If the TYPE directive is not set,
    # the device is treated as an Ethernet device
    # https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/s2-networkscripts-interfaces_network-bridge.html

    L23_stored_config <| title == $port_name |> {
      ensure          => $ensure,
      if_type         => $if_type,
      bridge          => $bridge,
      vlan_id         => $port_vlan_id,
      vlan_dev        => $port_vlan_dev,
      vlan_mode       => $port_vlan_mode,
      bond_master     => $master,
      mtu             => $mtu,
      onboot          => $onboot,
      ethtool         => $ethtool,
      delay_while_up  => $delay_while_up,
      vendor_specific => $vendor_specific,
      provider        => $config_provider
    }

    l2_port { $port_name :
      ensure          => $ensure,
      use_ovs         => $use_ovs,
      bridge          => $bridge,
      vlan_id         => $port_vlan_id,
      vlan_dev        => $port_vlan_dev,
      vlan_mode       => $port_vlan_mode,
      bond_master     => $master,
      mtu             => $mtu,
      onboot          => $onboot,
      #type           => $type,
      #trunks         => $trunks,
      ethtool         => $ethtool,
      vendor_specific => $vendor_specific,
      provider        => $provider
    }

    # this need for creating L2_port resource by ifup, if it allowed by OS
    L23_stored_config[$port_name] -> L2_port[$port_name]

    Anchor['l23network::init'] -> K_mod<||> -> L2_port<||>
  }

  if $::l23_os =~ /(?i:redhat|centos)/ {
    if $delay_while_up {
      file {"${::l23network::params::interfaces_dir}/interface-up-script-${port_name}":
        ensure  => present,
        owner   => 'root',
        mode    => '0755',
        content => template("l23network/centos_post_up.erb"),
      } -> L23_stored_config <| title == $port_name |>
    } else {
      file {"${::l23network::params::interfaces_dir}/interface-up-script-${port_name}":
        ensure  => absent,
      } -> L23_stored_config <| title == $port_name |>
    }
  }

}
# vim: set ts=2 sw=2 et :
