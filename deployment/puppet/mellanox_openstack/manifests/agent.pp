class mellanox_openstack::agent (
    $physnet,
    $physifc,
) {
    include mellanox_openstack::params

    $package      = $::mellanox_openstack::params::neutron_mlnx_packages
    $agent        = $::mellanox_openstack::params::agent_service
    $filters_dir  = $::mellanox_openstack::params::filters_dir
    $filters_file = $::mellanox_openstack::params::filters_file

    if $::osfamily == 'Debian' {
        File {
            owner  => 'root',
            group  => 'root',
        }

        file { 'filters_dir' :
            ensure => directory,
            path   => $filters_dir,
            mode   => '0755',
        }

        file { 'network.filters' :
            ensure => present,
            path   => $filters_file,
            mode   => '0644',
            source => 'puppet:///modules/mellanox_openstack/network.filters',
        }

        File <| title == '/etc/nova/nova.conf' |> ->
        File['filters_dir'] ->
        File['network.filters'] ~>
        Service[$service]
    }

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
