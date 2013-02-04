# == Class: l23network
#
# Module for configuring network. Contains L2 and L3 modules.
# Requirements, packages and services.
#
class l23network {
  class {'l23network::l2': }
}
