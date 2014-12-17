# == Define: l23network::l2::bridge
#
# Create open vSwitch brigde.
#
# === Parameters
#
# [*name*]
#   Bridge name.
#
# [*external_ids*]
#   See open vSwitch documentation.
#   http://openvswitch.org/cgi-bin/ovsman.cgi?page=utilities%2Fovs-vsctl.8
#
define l23network::l2::bridge (
  $ensure          = present,
  $mtu             = undef,
  $stp             = undef,
  $bpdu_forward    = true,
  $external_ids    = { 'bridge-id' => "${name}" },
  $provider        = undef,
) {
  include l23network::params

  if ! defined (L2_bridge[$name]) {
    if $provider {
      $config_provider = "${provider}_${::l23_os}"
    } else {
      $config_provider = undef
    }

    if ! defined (L23_stored_config[$name]) {
      l23_stored_config { $name: }
    }

    L23_stored_config <| title == $name |> {
      ensure       => $ensure,
      #bpdu_forward => $bpdu_forward,
      if_type         => 'bridge',
      bridge_stp      => $stp,
      bridge_ports    => ['none'],
      #vendor_specific=> $vendor_specific,
      provider        => $config_provider
    }

    l2_bridge {$name:
      ensure          => $ensure,
      external_ids    => $external_ids,
      stp             => $stp,
      #bpdu_forward   => $bpdu_forward,
      vendor_specific => $vendor_specific,
      provider        => $provider
    }

    # this need for creating L2_bridge resource by ifup, if it allowed by OS
    L23_stored_config[$name] -> L2_bridge[$name]

    K_mod<||> -> L2_bridge<||>
  }
}

