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
    file {'ocf-mirantis-path':
      path=>'/usr/lib/ocf/resource.d/mirantis', 
      #mode => 755,
      ensure => directory,
      recurse => true,
      owner => root,
      group => root,
    } 
    Package['corosync'] -> File['ocf-mirantis-path']
}
#
###