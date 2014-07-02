class mellanox_openstack::agent (
    $physnet,
    $physifc,
) {

    $package = $::mellanox_openstack::params::neutron_mlnx_packages

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

    service { 'mlnx-agent' :
        ensure     => running,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
    }

    Package[$package] ->
    Mellanox_agent_config <||> ~>
    Service['mlnx-agent']

}
