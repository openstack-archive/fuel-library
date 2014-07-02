class mellanox_openstack::agent (
    $physnet,
    $physifc,
) {
    include mellanox_openstack::params

    $package = $::mellanox_openstack::params::neutron_mlnx_packages
    $agent   = $::mellanox_openstack::params::agent_service

    Mellanox_agent_config {
        ensure  => present,
    }

    mellanox_agent_config {
        'agent/rpc_support_old_agents'        : value => true;
        'eswitch/physical_interface_mappings' : value => "${physnet}:${physifc}";
    }

    package { $package :
        ensure => installed,
    }

    service { $agent :
        ensure     => running,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
    }

    Package[$package] ->
    Mellanox_agent_config <||> ~>
    Service[$agent]

}
