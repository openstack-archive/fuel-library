# == Class: cluster
#
# Module for configuring cluster resources.
#
class cluster {
    if $use_unicast_corosync {
      #todo: make as parameter
      $unicast_addresses = $controller_internal_addresses
    } else {
      $unicast_addresses = undef
    }

    #todo: move half of openstack::corosync to this module, another half -- to quantum
    if defined(Stage['corosync_setup']) {
      class {'openstack::corosync':
        bind_address      => $internal_address,
        unicast_addresses => $unicast_addresses,
        stage             => 'corosync_setup'
      }
    } else {
      class {'openstack::corosync':
        bind_address      => $internal_address,
        unicast_addresses => $unicast_addresses
      }
    }
}
#
###