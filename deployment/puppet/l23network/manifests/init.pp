# == Class: l23network
#
# Module for configuring network. Contains L2 and L3 modules.
# Requirements, packages and services.
#
class l23network (
  $use_ovs       = true,
  $use_lnx       = true,
  $install_ovs   = true,
  $install_brctl = true,
){
  class {'l23network::l2':
    use_ovs       => $use_ovs,
    use_lnx       => $use_lnx,
    install_ovs   =>  $install_ovs,
    install_brctl =>  $install_brctl,
  }
}
#
###
