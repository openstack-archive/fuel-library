# == Class: cluster
#
# Module for configuring cluster resources.
#
class cluster (
    $internal_address  = '127.0.0.1',
    $unicast_addresses = undef,
) {
  #did not clean up due to it will be reworked later
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
        #FIXME(bogdando) use version 2 when Corosync 2.x packages merged
        #corosync_version  => '2',
        packages          => ['corosync', 'pacemaker', 'crmsh', $pcs_package],
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

}
