class mellanox_openstack::mlnx_agent_config ($physnet, $physifc) {

    Ini_setting {
        ensure => present,
        path => '/etc/neutron/plugins/mlnx/mlnx_conf.ini',
        require => Package['openstack-neutron-mellanox'],
        notify => Service['neutron-mlnx-agent']
    }

    $mlnx_conf = {
        "rpc_support_old_agents" => {
            section => 'agent',
            setting => 'rpc_support_old_agents',
            value => 'true'
        },
        "physical_interface_mappings" => {
            section => 'eswitch',
            setting => 'physical_interface_mappings',
            value => "$physnet:$physifc"
        },
    }
    create_resources(Ini_setting, $mlnx_conf)

    service { 'neutron-mlnx-agent':
        ensure => running,
        enable => true,
        require => Package[$::mellanox_openstack::params::neutron_mlnx_packages]
    }

}
