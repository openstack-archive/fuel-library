# == Define: l23network::l2::bridge
#
# Create open vSwitch brigde.
#
# === Parameters
#
# [*name*]
#   Bridge name.
#
# [*skip_existing*]
#   If this bridge already exists it will be ignored without any errors.
#   Must be true or false.
#
# [*external_ids*]
#   See open vSwitch documentation.
#   http://openvswitch.org/cgi-bin/ovsman.cgi?page=utilities%2Fovs-vsctl.8
#
define l23network::l2::bridge (
  $ensure          = present,
  $bpdu_forward    = true,
  $external_ids    = "bridge-id=${name}",
  $skip_existing   = false,
  $provider        = undef,
) {
  include l23network::params

  if ! defined (L2_bridge[$name]) {

    if $provider {
      $config_provider = "${provider}_${::l23_os}"
    } else {
      $config_provider = undef
    }

    Anchor['l23network::init'] ->
    l23_store_config {"l2_br_config_file__${name}":
      ensure   => $ensure,
      file     => "ifcfg-${name}",
      config   => {
                    name            => $name,
                    external_ids    => $external_ids,
                    bpdu_forward    => $bpdu_forward,
                  },
      provider => $config_provider
    } ->
    l2_bridge {$name:
      ensure        => $ensure,
      external_ids  => $external_ids,
      skip_existing => $skip_existing,
      provider      => $provider
    }
  }
}

