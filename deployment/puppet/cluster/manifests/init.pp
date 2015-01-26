# == Class: cluster
#
# Module for configuring cluster resources.
#
class cluster (
    $internal_address  = '127.0.0.1',
    $unicast_addresses = undef,
) {

    #todo: move half of openstack::corosync
    #to this module, another half -- to Neutron
    if defined(Stage['corosync_setup']) {

      case $::osfamily {
        'RedHat': {
          $pcs_package = 'pcs'
        }
        'Debian': {
          $pcs_package = 'python-pcs'
        }
         default: {
          fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem},\
 module ${module_name} only support osfamily RedHat and Debian")
        }
      }

      class { 'openstack::corosync':
        bind_address      => $internal_address,
        unicast_addresses => $unicast_addresses,
        stage             => 'corosync_setup',
        #FIXME(bogdando) use version 2 when Corosync 2.x packages merged
        corosync_version  => '2',
        packages          => ['corosync', 'pacemaker', 'crmsh', $pcs_package],
      }
    } else {
      class { 'openstack::corosync':
        bind_address      => $internal_address,
        unicast_addresses => $unicast_addresses,
        #FIXME(bogdando) use version 2 when Corosync 2.x packages merged
        corosync_version  => '2',
        packages          => ['corosync', 'pacemaker', 'crmsh', $pcs_package],      }
    }
    file { 'ocf-fuel-path':
      ensure  => directory,
      path    =>'/usr/lib/ocf/resource.d/fuel',
      recurse => true,
      owner   => 'root',
      group   => 'root',
    }
    Package['corosync'] -> File['ocf-fuel-path']
    Package<| title == 'pacemaker' |> -> File['ocf-fuel-path']

    file { 'ns-ipaddr2-ocf':
      path   =>'/usr/lib/ocf/resource.d/fuel/ns_IPaddr2',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => 'puppet:///modules/cluster/ocf/ns_IPaddr2',
    }

    Package['pacemaker'] -> File['ns-ipaddr2-ocf']
    File<| title == 'ocf-fuel-path' |> -> File['ns-ipaddr2-ocf']

}
#
###
