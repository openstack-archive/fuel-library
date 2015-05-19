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
  $use_ovs         = $::l23network::use_ovs,
  $mtu             = undef,
  $stp             = undef,
  $bpdu_forward    = true,
# $bridge_id       = undef,  # will be implemented later
  $external_ids    = { 'bridge-id' => "${name}" },
  $delay_while_up  = undef,
  $vendor_specific = undef,
  $provider        = undef,
) {
  include ::stdlib
  include ::l23network::params

  if ! defined (L2_bridge[$name]) {
    if $provider {
      $config_provider = "${provider}_${::l23_os}"
    } else {
      $config_provider = undef
    }

    if $delay_while_up and ! is_numeric($delay_while_up) {
      fail("Delay for waiting after UP bridge ${name} should be numeric, not an '$delay_while_up'.")
    }

    if ! defined (L23_stored_config[$name]) {
      l23_stored_config { $name: }
    }

    L23_stored_config <| title == $name |> {
      ensure       => $ensure,
      #bpdu_forward => $bpdu_forward,
      if_type         => 'bridge',
      bridge_stp      => $stp,
      bridge_ports    => ['none'],  # this property will be fulled by l2_port
      vendor_specific => $vendor_specific,
      delay_while_up  => $delay_while_up,
      provider        => $config_provider
    }

    l2_bridge {$name:
      ensure          => $ensure,
      use_ovs         => $use_ovs,
      external_ids    => $external_ids,
      stp             => $stp,
      #bpdu_forward   => $bpdu_forward,
      vendor_specific => $vendor_specific,
      provider        => $provider
    }

    # this need for creating L2_bridge resource by ifup, if it allowed by OS
    L23_stored_config[$name] -> L2_bridge[$name]

    Anchor['l23network::init'] -> K_mod<||> -> L2_bridge<||>
  }

  if $::osfamily =~ /(?i)redhat/ {
    if $delay_while_up {
      file {"${::l23network::params::interfaces_dir}/interface-up-script-${name}":
        ensure  => present,
        owner   => 'root',
        mode    => '0755',
        content => template("l23network/centos_post_up.erb"),
      } -> L23_stored_config <| title == $name |>
    } else {
      file {"${::l23network::params::interfaces_dir}/interface-up-script-${name}":
        ensure  => absent,
      } -> L23_stored_config <| title == $name |>
    }
  }

}

