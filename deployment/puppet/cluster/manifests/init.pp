# == Class: cluster
#
# Module for configuring cluster resources.
#
class cluster (
    $internal_address = "127.0.0.1",
    $unicast_addresses = undef,
)
{
    #todo: move half of openstack::corosync to this module, another half -- to Neutron
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
    Package<| title == 'pacemaker' |> -> File['ocf-mirantis-path']

    file {'ns-ipaddr2-ocf':
      path   =>'/usr/lib/ocf/resource.d/mirantis/ns_IPaddr2',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => "puppet:///modules/cluster/ns_IPaddr2",
    }

    Package['pacemaker'] -> File['ns-ipaddr2-ocf']
    File<| title == 'ocf-mirantis-path' |> -> File['ns-ipaddr2-ocf']

}
#
###
