class mellanox_openstack::eswitchd_config ($physnet, $physifc) {

    Ini_setting {
        ensure => present,
        path => '/etc/eswitchd/eswitchd.conf',
        require => Package['eswitchd'],
        notify => Service['eswitchd']
    }

    $eswitchd_conf = {
        "fabrics" => {
            section => 'DAEMON',
            setting => 'fabrics',
            value => "$physnet:$physifc"
        },
    }
    create_resources(Ini_setting, $eswitchd_conf)

    service { 'eswitchd':
        ensure => running,
        enable => true,
        before => Service['neutron-mlnx-agent'],
        require => Package[$::mellanox_openstack::params::eswitchd_package]
    }

}
