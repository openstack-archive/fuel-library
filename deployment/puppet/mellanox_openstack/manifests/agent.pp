class mellanox_openstack::agent (
    $physnet,
    $physifc,
) {
    include mellanox_openstack::params

    $package              = $::mellanox_openstack::params::neutron_mlnx_packages
    $agent                = $::mellanox_openstack::params::agent_service
    $filters_dir          = $::mellanox_openstack::params::filters_dir
    $filters_file         = $::mellanox_openstack::params::filters_file
    $compute_service_name = $::mellanox_openstack::params::compute_service_name

    # Only relevant for Debian since no package provides network.filters file
    if $::osfamily == 'Debian' {
        File {
            owner  => 'root',
            group  => 'root',
        }

        file { $filters_dir :
            ensure => directory,
            mode   => '0755',
        }

        file { $filters_file :
            ensure => present,
            mode   => '0644',
            source => 'puppet:///modules/mellanox_openstack/network.filters',
        }

        File <| title == '/etc/nova/nova.conf' |> ->
        File[$filters_dir] ->
        File[$filters_file] ~>
        Service[$compute_service_name]
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

    Package[$package] ~>
    Service[$agent]

}
