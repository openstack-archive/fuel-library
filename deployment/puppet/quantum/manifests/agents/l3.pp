#
class quantum::agents::l3 (
  $package_ensure   = 'present',
  $enabled          = true,
  $debug            = 'False',
  $fixed_range      = '10.0.1.0/24',
  $floating_range   = '192.168.10.0/24',
  $ext_ipinfo       = { },
  $segment_range    = '1:4094',
  $tenant_network_type = 'gre',
  $create_networks  = true,
  $interface_driver = 'quantum.agent.linux.interface.OVSInterfaceDriver',
  $external_network_bridge = 'br-ex',
  $auth_url         = 'http://localhost:5000/v2.0',
  $auth_port        = '5000',
  $auth_region      = 'RegionOne',
  $auth_tenant      = 'services',
  $auth_user        = 'quantum',
  $auth_password    = 'password',
  $root_helper      = 'sudo /usr/bin/quantum-rootwrap /etc/quantum/rootwrap.conf',
  $use_namespaces   = 'True',
  $router_id        = undef,
  $gateway_external_net_id      = undef,
  $handle_internal_only_routers = 'True',
  $metadata_ip      = '169.254.169.254',
  $metadata_port    = 8775,
  $polling_interval = 3,
  $service_provider = 'generic'
) {
  include 'quantum::params'

  if $::quantum::params::l3_agent_package {
    Package['quantum'] -> Package['quantum-l3']
    $l3_agent_package = 'quantum-l3'

    package { 'quantum-l3':
      name   => $::quantum::params::l3_agent_package,
      ensure => $package_ensure,
    }
  } else {
    $l3_agent_package = $::quantum::params::package_name
  }

  include 'quantum::waist_setup'

  Quantum_l3_agent_config <| |> -> Class[quantum::waistline]

  #quantum::agents::sysctl{"$l3_agent_package": }

  Package[$l3_agent_package] -> Quantum_l3_agent_config <| |>
  Quantum_config <| |> -> Quantum_l3_agent_config <| |>
  Quantum_l3_agent_config <| |> -> Service['quantum-l3']
  Quantum_config <| |> ~> Service['quantum-l3']
  Quantum_l3_agent_config <| |> ~> Service['quantum-l3']
  Quantum_l3_agent_config <| |> -> Quantum_router <| |>
  Quantum_l3_agent_config <| |> -> Quantum_net <| |>
  Quantum_l3_agent_config <| |> -> Quantum_subnet <| |>

  quantum_l3_agent_config {
    'DEFAULT/debug':
      value => $debug;

    'DEFAULT/auth_url':
      value => $auth_url;

    'DEFAULT/auth_port':
      value => $auth_port;

    'DEFAULT/admin_tenant_name':
      value => $auth_tenant;

    'DEFAULT/admin_user':
      value => $auth_user;

    'DEFAULT/admin_password':
      value => $auth_password;

    'DEFAULT/use_namespaces':
      value => $use_namespaces;

    # 'DEFAULT/router_id':                      value => $router_id;
    # 'DEFAULT/gateway_external_net_id':        value => $gateway_external_net_id;
    'DEFAULT/metadata_ip':
      value => $metadata_ip;

    'DEFAULT/external_network_bridge':
      value => $external_network_bridge;

    'DEFAULT/root_helper':
      value => $root_helper;
  }

  if $enabled {
    $ensure = 'running'

    if $create_networks {
      L23network::L2::Bridge <| |> -> Quantum::Network::Setup <| |>

      $segment_id = regsubst($segment_range, ':\d+', '')

      if $tenant_network_type == 'gre' {
        $internal_physical_network = undef
        $external_physical_network = undef
        $external_network_type = $tenant_network_type
        $external_segment_id = $segment_id + 1
      } else {
        $internal_physical_network = 'physnet2'
        $external_physical_network = 'physnet1'
        $external_network_type = 'flat'
        $external_segment_id = undef
      }

      if empty($ext_ipinfo) {
        $floating_net = regsubst($floating_range, '(.+\.)\d+/\d+', '\1')
        $floating_host = regsubst($floating_range, '.+\.(\d+)/\d+', '\1') + 1

        $external_gateway = "${floating_net}${floating_host}"
        $external_alloc_pool = undef
      } else {
        $external_gateway = $ext_ipinfo['public_net_router']
        $external_alloc_pool = [$ext_ipinfo['pool_start'], $ext_ipinfo['pool_end']]
      }

      Keystone_user_role<| title=="$auth_user@$auth_tenant"|> -> Quantum::Network::Setup <| |>
      Keystone_user_role<| title=="$auth_user@$auth_tenant"|> -> Quantum::Network::Provider_router <| |>

      quantum::network::setup { 'net04':
        physnet      => $internal_physical_network,
        network_type => $tenant_network_type,
        segment_id   => $segment_id,
        subnet_name  => 'subnet04',
        subnet_cidr  => $fixed_range,
        nameservers  => '8.8.4.4',
      }
      Quantum_l3_agent_config <| |> -> Quantum::Network::Setup['net04']

      quantum::network::setup { 'net04_ext':
        tenant_name     => 'services',
        physnet         => $external_physical_network,
        network_type    => $external_network_type,
        segment_id      => $external_segment_id, # undef,
        router_external => 'True',
        subnet_name     => 'subnet04_ext',
        subnet_cidr     => $floating_range,
        subnet_gw       => $external_gateway, # undef,
        alloc_pool      => $external_alloc_pool, # undef,
        enable_dhcp     => 'False', # 'True',
        shared          => 'True',
      }
      Quantum_l3_agent_config <| |> -> Quantum::Network::Setup['net04_ext']

      # router_info = quantum('--os-tenant-name', @auth_hash['admin_tenant_name'], '--os-username', @auth_hash['admin_user'],
      # '--os-password', @auth_hash['admin_password'], '--os-auth-url', @auth_hash['auth_url'], 'router-show', @name)
      quantum::network::provider_router { 'router04':
        router_subnets => 'subnet04', # undef,
        router_extnet  => 'net04_ext', # undef,
        notify         => Service['quantum-l3'],
        auth_tenant    => $auth_tenant,
        auth_user      => $auth_user,
        auth_password  => $auth_password,
        auth_url       => $auth_url
      }
      Quantum::Network::Setup['net04_ext'] -> Quantum::Network::Provider_router['router04']

      # turn down the current default route metric priority
      # TODO: make function for recognize REAL defaultroute
      # temporary use
      $update_default_route_metric = "bash -c \"(/sbin/ip route delete default via ${::default_gateway} || exit 0 ) && /sbin/ip route replace default via ${::default_gateway} metric 100\""

      exec { 'update_default_route_metric':
        command     => $update_default_route_metric,
        returns     => [0, 7],
        refreshonly => true,
        path      => ['/usr/bin', '/bin', '/sbin', '/usr/sbin']
      }
      Quantum::Network::Provider_router['router04'] -> Exec['update_default_route_metric']
      Class[quantum::waistline] -> Quantum::Network::Setup <| |>
      Class[quantum::waistline] -> Quantum::Network::Provider_router <| |>
      Class[quantum::waistline] -> Exec[update_default_route_metric]

      exec { 'setup_router_id':
        command   => "/bin/bash -c \"eval `quantum --os-tenant-name ${auth_tenant} --os-auth-url ${auth_url} --os-username ${auth_user} --os-password ${auth_password} router-show router04 -f shell | grep -E '^id'` && sed -r -i -e \\\"s/^router_id\s*=.*\$//\\\" /etc/quantum/l3_agent.ini && echo router_id=\\\$id >> /etc/quantum/l3_agent.ini\"",
        logoutput => 'on_failure',
        tries     => 5,
        try_sleep => 3,
        path      => ['/usr/bin', '/bin', '/sbin', '/usr/sbin']
      }

      Quantum_l3_agent_config <| |> -> Exec['setup_router_id']
      Exec['setup_router_id'] ~> Service['quantum-l3']
      Package[$l3_agent_package] ~> Exec['update_default_route_metric']
      Exec['update_default_route_metric'] -> Service['quantum-l3'] -> Exec['settle-down-default-route']

      exec { 'settle-down-default-route':
        command     => "/bin/ping -q -W2 -c1 ${external_gateway}",
        subscribe   => Exec['update_default_route_metric'],
        logoutput   => 'on_failure',
        refreshonly => true,
        try_sleep   => 3,
        tries       => 5,
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

  Service<| title == 'quantum-server' |>->Service['quantum-l3'] 

  if $service_provider == 'pacemaker' {
    
    Service<| title == 'quantum-server' |> -> Cs_shadow['l3']
    Quantum_l3_agent_config <||> -> Cs_shadow['l3']
    cs_resource { "p_${::quantum::params::l3_agent_service}":
      ensure          => present,
      cib             => 'l3',
      primitive_class => 'ocf',
      provided_by     => 'pacemaker',
      primitive_type  => 'quantum-agent-l3',
      require         => File['quantum-l3-agent'],
      parameters      => {
        'os_auth_url' => $auth_url,
        'tenant'      => $auth_tenant,
        'username'    => $auth_user,
        'password'    => $auth_password,
      }
      ,
      operations      => {
        'monitor'  => {
          'interval' => '20',
          'timeout'  => '30'
        }
        ,
        'start'    => {
          'timeout' => '360'
        }
        ,
        'stop'     => {
          'timeout' => '360'
        }

      }
      ,
    }

    cs_shadow { 'l3': cib => 'l3' }

    cs_commit { 'l3': cib => 'l3' }

    Cs_commit <| title == 'dhcp' |> -> Cs_shadow <| title == 'l3' |>
    Cs_commit <| title == 'ovs' |> -> Cs_shadow <| title == 'l3' |>

    Cs_commit['l3'] -> Service['quantum-l3']
    ::corosync::cleanup{"p_${::quantum::params::l3_agent_service}":}
    
    Cs_commit['l3'] -> ::Corosync::Cleanup["p_${::quantum::params::l3_agent_service}"]
    Cs_commit['l3'] ~> ::Corosync::Cleanup["p_${::quantum::params::l3_agent_service}"]
    ::Corosync::Cleanup["p_${::quantum::params::l3_agent_service}"]->Service['quantum-l3']
    
    Cs_resource["p_${::quantum::params::l3_agent_service}"] -> Cs_colocation['l3-with-ovs']
    Cs_resource["p_${::quantum::params::l3_agent_service}"] -> Cs_order['l3-after-ovs']

    cs_colocation { 'l3-with-ovs':
      ensure     => present,
      cib        => 'l3',
      primitives => ["p_${::quantum::params::l3_agent_service}", "clone_p_${::quantum::params::ovs_agent_service}"],
      score      => 'INFINITY',
    }
    cs_order { 'l3-after-ovs':
      ensure => present,
      cib    => 'l3',
      first  => "clone_p_${::quantum::params::ovs_agent_service}",
      second => "p_${::quantum::params::l3_agent_service}",
      score  => 'INFINITY',
    }

    # start DHCP and L3 agents on different controllers if it's possible
    cs_colocation { 'dhcp-without-l3':
      ensure     => present,
      cib        => 'l3',
      primitives => ["p_${::quantum::params::dhcp_agent_service}", "p_${::quantum::params::l3_agent_service}"],
      score      => '-100',
    }

    # Ensure service is stopped  and disabled by upstart/init/etc.
    Service['quantum-l3-init_stopped'] -> Cs_resource["p_${::quantum::params::l3_agent_service}"]

    service { 'quantum-l3-init_stopped':
      name       => "${::quantum::params::l3_agent_service}",
      enable     => false,
      ensure     => stopped,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::quantum::params::service_provider,
      require    => [Package[$l3_agent_package], Class['quantum']],
    }

    service { 'quantum-l3':
      name       => "p_${::quantum::params::l3_agent_service}",
      enable     => $enabled,
      ensure     => $ensure,
      hasstatus  => true,
      hasrestart => false,
      provider   => "pacemaker",
      require    => [Package[$l3_agent_package], Class['quantum'], Service['quantum-ovs-agent']],
    }
  } else {
    service { 'quantum-l3':
      name       => $::quantum::params::l3_agent_service,
      enable     => $enabled,
      ensure     => $ensure,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::quantum::params::service_provider,
      require    => [Package[$l3_agent_package], Class['quantum'], Service['quantum-ovs-agent']],
    }
  }
}
