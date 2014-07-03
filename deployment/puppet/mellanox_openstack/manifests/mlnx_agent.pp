class mellanox_openstack::mlnx_agent (
    $physnet,
    $physifc,
) {

    $agent_package   = $::mellanox_openstack::params::neutron_mlnx_packages
    $mlnxvif_package = $::mellanox_openstack::params::mlnxvif_package

    Mellanox_agent_config {
        ensure  => present,
    }

    mellanox_agent_config {
        'agent/rpc_support_old_agents'        : value => true;
        'eswitch/physical_interface_mappings' : value => "${physnet}:${physifc}";
    }

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
    Mellanox_agent_config <||> ~>
    Service['neutron-mlnx-agent']

}
