class mellanox_openstack::mlnx_agent (
    $physnet,
    $physifc,
) {

    $agent_package   = $::mellanox_openstack::params::neutron_mlnx_packages
    $mlnxvif_package = $::mellanox_openstack::params::mlnxvif_package

    $defaults = {
        ensure  => present,
        path    => '/etc/neutron/plugins/mlnx/mlnx_conf.ini',
        require => Package[$agent_package],
        notify  => Service['neutron-mlnx-agent']
    }

    $mlnx_conf = {
        'rpc_support_old_agents' => {
            section => 'agent',
            setting => 'rpc_support_old_agents',
            value   => 'true',
        },
        'physical_interface_mappings' => {
            section => 'eswitch',
            setting => 'physical_interface_mappings',
            value   => "${physnet}:${physifc}",
        },
    }

    #TODO: make mellanox_neutron_agent_config resource type
    create_resources(Ini_setting, $mlnx_conf, $defaults)

    package { $agent_package :
        ensure => installed,
    }

    package { $mlnxvif_package :
        ensure => installed,
    }

    service { 'neutron-mlnx-agent' :
        ensure  => running,
        enable  => true,
    }

    Package[$mlnxvif_package] ->
    Package[$agent_package] ->
    Service['neutron-mlnx-agent']

}
