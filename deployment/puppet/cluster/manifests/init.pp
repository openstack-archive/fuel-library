# == Class: cluster
#
# Module for configuring cluster resources.
#
class cluster (
    $internal_address         = '127.0.0.1',
    $corosync_nodes           = undef,
) {

    #todo: move half of openstack::corosync
    #to this module, another half -- to Neutron

    if defined(Stage['corosync_setup']) {
      class { 'openstack::corosync':
        bind_address             => $internal_address,
        corosync_nodes           => $corosync_nodes,
        stage                    => 'corosync_setup',
        corosync_version         => '2',
        packages                 => ['corosync', 'pacemaker', 'crmsh', 'pcs'],
      }
    } else {
      class { 'openstack::corosync':
        bind_address             => $internal_address,
        corosync_nodes           => $corosync_nodes,
        corosync_version         => '2',
        packages                 => ['corosync', 'pacemaker', 'crmsh', 'pcs'],
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
