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
      class { 'openstack::corosync':
        bind_address      => $internal_address,
        unicast_addresses => $unicast_addresses,
        stage             => 'corosync_setup',
        corosync_version  => '2',
        packages          => ['corosync', 'pacemaker', 'crmsh', 'pcs'],
      }
    } else {
      class { 'openstack::corosync':
        bind_address      => $internal_address,
        unicast_addresses => $unicast_addresses,
        corosync_version  => '2',
        packages          => ['corosync', 'pacemaker', 'crmsh', 'pcs'],
      }
    }

    # NOTE(bogdando) dirty hack to make corosync with pacemaker service ver:1 working #1417972
    exec { 'stop-pacemaker':
      command     => 'service pacemaker stop || true',
      path        => '/bin:/usr/bin/:/sbin:/usr/sbin',
    }
    File<| title == '/etc/corosync/corosync.conf' |> ~> Exec['stop-pacemaker'] ~> Service['corosync']

    # NOTE(bogdando) #LP1445478 - lower the validator version for Ubuntu
    if ($::osfamily == 'Debian') {
      # Use retries as CIB require some time to become ready
      exec { 'fix-crm-validator':
        command   => 'cibadmin --modify --xml-text \'<cib validate-with="pacemaker-1.2"/>\'',
        path      => '/bin:/usr/bin/:/sbin:/usr/sbin',
        tries     => 10,
        try_sleep => 30,
        require   => Class['openstack::corosync'],
      }
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
