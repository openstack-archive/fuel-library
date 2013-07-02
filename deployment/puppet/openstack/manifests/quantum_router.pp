#This class installs quantum WITHOUT quantum api server which is installed on controller nodes

class openstack::quantum_router (
  $db_host,
  $rabbit_password,
  $internal_address         = $::ipaddress_br_mgmt,
  $public_interface         = "br-ex",
  $private_interface        = "br-mgmt",
  $fixed_range              = '10.0.0.0/24',
  $floating_range           = false,
  $external_ipinfo          = {},
  $create_networks          = true,
  $segment_range            = '1:4094',
  $service_endpoint         = '127.0.0.1',
  $rabbit_user              = 'nova',
  $rabbit_nodes             = ['127.0.0.1'],
  $rabbit_ha_virtual_ip     = false,
  $db_type                  = 'mysql',
  $auth_host                = '127.0.0.1',
  $verbose                  = 'False',
  $debug                    = 'False',
  $enabled                  = true,
  $ensure_package           = present,
  $api_bind_address         = '0.0.0.0',
  $quantum                  = false,
  $quantum_db_dbname        = 'quantum',
  $quantum_db_user          = 'quantum',
  $quantum_db_password      = 'quantum_pass',
  $quantum_user_password    = 'quantum_pass',
  $exported_resources       = true,
  $quantum_gre_bind_addr    = $internal_address,
  $quantum_network_node     = false,
  $quantum_netnode_on_cnt   = false,  
  $tenant_network_type      = 'gre',
  $use_syslog               = false,
  $ha_mode                  = false,
  $service_provider         = 'generic'
) {
    # Set up Quantum
    $quantum_sql_connection = "$db_type://${quantum_db_user}:${quantum_db_password}@${db_host}/${quantum_db_dbname}?charset=utf8"
    $enable_tunneling       = $tenant_network_type ? { 'gre' => true, 'vlan' => false }
    $admin_auth_url = "http://${auth_host}:35357/v2.0"

    class { '::quantum':
      bind_host            => $api_bind_address,
      rabbit_user          => $rabbit_user,
      rabbit_password      => $rabbit_password,
      rabbit_host          => $rabbit_nodes,
      rabbit_ha_virtual_ip => $rabbit_ha_virtual_ip,
      verbose              => $verbose,
      debug                => $verbose,
      use_syslog           => $use_syslog,
      server_ha_mode       => $ha_mode,

    }
    class { 'quantum::plugins::ovs':
      bridge_mappings     => ["physnet1:br-ex","physnet2:br-prv"],
      network_vlan_ranges => "physnet1,physnet2:${segment_range}",
      tunnel_id_ranges    => "${segment_range}",
      sql_connection      => $quantum_sql_connection,
      tenant_network_type => $tenant_network_type,
      enable_tunneling    => $enable_tunneling,
    }

    if $quantum_network_node {
      class { 'quantum::agents::ovs':
        bridge_uplinks   => ["br-prv:${private_interface}"],
        bridge_mappings  => ['physnet2:br-prv'],
        enable_tunneling => $enable_tunneling,
        local_ip         => $internal_address,
        service_provider => $service_provider
      }
      class { 'quantum::agents::dhcp':
        debug            => True,
        use_namespaces   => False,
        service_provider => $service_provider,
        auth_url         => $admin_auth_url,
        auth_tenant      => 'services',
        auth_user        => 'quantum',
        auth_password    => $quantum_user_password,
      }
      class { 'quantum::agents::l3':
       #enabled             => $quantum_l3_enable,
        debug               => True,
        fixed_range         => $fixed_range,
        floating_range      => $floating_range,
        ext_ipinfo          => $external_ipinfo,
        tenant_network_type => $tenant_network_type,
        create_networks     => $create_networks,
        segment_range       => $segment_range,
        auth_url            => $admin_auth_url,
        auth_tenant         => 'services',
        auth_user           => 'quantum',
        auth_password       => $quantum_user_password,
        use_namespaces      => False,
        metadata_ip         => $internal_address,
        service_provider    => $service_provider
      }
    }

    if !defined(Sysctl::Value['net.ipv4.ip_forward']) {
      sysctl::value { 'net.ipv4.ip_forward': value => '1'}
    }
}
