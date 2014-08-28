class mellanox_openstack::eswitchd (
    $physnet,
    $physifc,
) {
    include mellanox_openstack::params

    $package = $::mellanox_openstack::params::eswitchd_package

    mellanox_eswitchd_config {
        'DAEMON/fabrics': value => "${physnet}:${physifc}";
    }

    package { $package :
        ensure => installed,
    }

    service { 'eswitchd' :
        ensure => running,
        enable => true,
        hasstatus  => true,
        hasrestart => true,
    }

    Package[$package] ->
    Mellanox_eswitchd_config <||> ~>
    Service['eswitchd']

    Package[$package] ~>
    Service['eswitchd']

}
