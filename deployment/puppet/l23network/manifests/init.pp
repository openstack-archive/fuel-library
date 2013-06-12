# == Class: l23network
#
# Module for configuring network. Contains L2 and L3 modules.
# Requirements, packages and services.
#
class l23network (
  $use_ovs   = true,
  $use_lnxbr = true,
){
  class {'l23network::l2': 
    use_ovs   => $use_ovs,
    use_lnxbr => $use_lnxbr,
  }
}
#
###