# == Class: cluster
#
# Module for configuring cluster resources.
#
class cluster (
    $internal_address         = '127.0.0.1',
    $quorum_members           = ['localhost'],
    $unicast_addresses        = ['127.0.0.1'],
    $cluster_recheck_interval = '190s',
) {

    #todo: move half of openstack::corosync
    #to this module, another half -- to Neutron

    if defined(Stage['corosync_setup']) {
      class { 'openstack::corosync':
        bind_address             => $internal_address,
        stage                    => 'corosync_setup',
        quorum_members           => $quorum_members,
        unicast_addresses        => $unicast_addresses,
        packages                 => 'crmsh',
        cluster_recheck_interval => $cluster_recheck_interval,
      }
    } else {
      class { 'openstack::corosync':
        bind_address             => $internal_address,
        quorum_members           => $quorum_members,
        unicast_addresses        => $unicast_addresses,
        packages                 => 'crmsh',
        cluster_recheck_interval => $cluster_recheck_interval,
      }
    }

    File<| title == '/etc/corosync/corosync.conf' |> -> Service['corosync']

    file { 'ocf-fuel-path':
      ensure  => directory,
      path    =>'/usr/lib/ocf/resource.d/fuel',
      recurse => true,
      owner   => 'root',
      group   => 'root',
    }
    Package['corosync'] -> File['ocf-fuel-path']
    Package<| title == 'pacemaker' |> -> File['ocf-fuel-path']

}
