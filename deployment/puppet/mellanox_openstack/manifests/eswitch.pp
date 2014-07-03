class mellanox_openstack::eswitchd (
    $physnet,
    $physifc,
) {

    $package = $::mellanox_openstack::params::eswitchd_package

    $defaults = {
        ensure  => present,
        path    => '/etc/eswitchd/eswitchd.conf',
        require => Package[$package],
        notify  => Service['eswitchd'],
    }

    $eswitchd_conf = {
        "fabrics" => {
            section => 'DAEMON',
            setting => 'fabrics',
            value   => "${physnet}:${physifc}",
        },
    }

    #TODO: make mellanox_eswitchd_config resource type
    create_resources(Ini_setting, $eswitchd_conf, $defaults)

    package { $package :
        ensure => installed,
    }

    service { 'eswitchd' :
        ensure => running,
        enable => true,
    }

    Package[$package] ->
    Service['eswitchd']

}
