#
class quantum::agents::l3 (
  $package_ensure               = 'present',
  $enabled                      = true,
  $debug                        = 'False',
  $fixed_range                  = '10.0.1.0/24',
  $floating_range               = '192.168.10.0/24',
  $ext_ipinfo                   = {},
  $segment_range                = '1:4094',
  $tenant_network_type          = 'gre',
  $create_networks              = true,
  $interface_driver             = 'quantum.agent.linux.interface.OVSInterfaceDriver',
  $external_network_bridge      = 'br-ex',
  $auth_url                     = 'http://localhost:5000/v2.0',
  $auth_port                    = '5000',
  $auth_region                  = 'RegionOne',
  $auth_tenant                  = 'service',
  $auth_user                    = 'quantum',
  $auth_password                = 'password',
  $root_helper                  = 'sudo /usr/bin/quantum-rootwrap /etc/quantum/rootwrap.conf',
  $use_namespaces               = 'True',
  $router_id                    = '7e5c2aca-bbac-44dd-814d-f2ea9a4003e4',
  $gateway_external_net_id      = '3f8699d7-f221-421a-acf5-e41e88cfd54f',
  $handle_internal_only_routers = 'True',
  $metadata_ip                  = '169.254.169.254',
  $metadata_port                = 8775,
  $polling_interval             = 3
) {

  include 'quantum::params'

  if $::quantum::params::l3_agent_package {
    Package['quantum'] -> Package['quantum-l3']
    $l3_agent_package = 'quantum-l3'

    package { 'quantum-l3':
      name    => $::quantum::params::l3_agent_package,
      ensure  => $package_ensure,
    }
  } else {
    $l3_agent_package = $::quantum::params::package_name
  }

  Package[$l3_agent_package] -> Quantum_l3_agent_config<||>
  Quantum_config<||> ~> Service['quantum-l3']
  Quantum_l3_agent_config<||> ~> Service['quantum-l3']

  quantum_l3_agent_config {
    'DEFAULT/debug':                          value => $debug;
    'DEFAULT/auth_url':                       value => $auth_url;
    'DEFAULT/auth_port':                      value => $auth_port;
    'DEFAULT/admin_tenant_name':              value => $auth_tenant;
    'DEFAULT/admin_user':                     value => $auth_user;
    'DEFAULT/admin_password':                 value => $auth_password;
    'DEFAULT/use_namespaces':                 value => $use_namespaces;
    'DEFAULT/router_id':                      value => $router_id;
    # 'DEFAULT/gateway_external_net_id':        value => $gateway_external_net_id;
    'DEFAULT/metadata_ip':                    value => $metadata_ip;
    'DEFAULT/external_network_bridge':        value => $external_network_bridge;
    'DEFAULT/root_helper':                    value => $root_helper;
  }

  if $enabled {
    $ensure = 'running'

    if $create_networks {
      package { 'python-keystoneclient':
        ensure => present,
        before => Exec['create-networks']
      }

      # create external/internal networks
      file { '/tmp/quantum-networking.sh':
        mode    => 740,
        owner   => root,
        content => template("quantum/quantum-networking.sh.${::osfamily}.erb"),
        require => Service['quantum-l3'],
        notify  => Exec['create-networks'],
      }
  
      package { 'cidr-package':
        name => $::quantum::params::cidr_package,
        ensure => $package_ensure,
        before => Exec['create-networks']
      }
  
      exec { 'create-networks':
        command     => '/tmp/quantum-networking.sh',
        # path        => '/usr/bin',
        refreshonly => true,
        logoutput   => true,
        require     => Service["openvswitch-switch"],
        #notify      => Service['quantum-plugin-ovs-service'],
      }
    }
  } else {
    $ensure = 'stopped'
  }

  $iptables_manager = "/usr/lib/${::quantum::params::python_path}/quantum/agent/linux/iptables_manager.py"

  # rootwrap error with L3 agent
  # https://bugs.launchpad.net/quantum/+bug/1069966
  exec { 'patch-iptables-manager':
    command => "sed -i '272 s|/sbin/||' ${iptables_manager}",
    onlyif  => "sed -n '272p' ${iptables_manager} | grep -q '/sbin/'",
    path    => '/bin/',
    require => Package[$l3_agent_package],
  }

  service { 'quantum-l3':
    name       => $::quantum::params::l3_agent_service,
    enable     => $enabled,
    ensure     => $ensure,
    hasstatus  => true,
    hasrestart => true,
    provider   => $::quantum::params::service_provider,
    require    => [Package[$l3_agent_package], Class['quantum']],
  }

}
