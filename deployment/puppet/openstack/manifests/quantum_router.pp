#This class installs quantum WITHOUT quantum api server which is installed on controller nodes

class openstack::quantum_router (
  $db_host,
  $rabbit_password,
  $internal_address         = $ipaddress_eth0,
  $public_interface         = "eth0",
  $private_interface        = "eth1",
  $fixed_range              = '10.0.0.0/24',
  $floating_range           = false,
  $create_networks          = true,
  $service_endpoint         = '127.0.0.1',
  $rabbit_user              = 'nova',
  $rabbit_nodes             = ['127.0.0.1'],
  $db_type                  = 'mysql',
  $auth_host                = '127.0.0.1',
  $verbose                  = 'False',
  $debug                    = 'False',
  $enabled                  = true,
  $exported_resources       = true,
  $ensure_package           = present,
  $api_bind_address         = '0.0.0.0',
  $quantum                  = false,
  $quantum_db_dbname        = 'quantum',
  $quantum_db_user          = 'quantum',
  $quantum_db_password      = 'quantum_pass',
  $quantum_user_password    = 'quantum_pass',
  $tenant_network_type      = 'gre',
)
{
    # Set up Quantum
    $quantum_sql_connection = "$db_type://${quantum_db_user}:${quantum_db_password}@${db_host}/${quantum_db_dbname}?charset=utf8"
    $enable_tunneling       = $tenant_network_type ? { 'gre' => true, 'vlan' => false }

    class { '::quantum':
      bind_host       => $api_bind_address,
      rabbit_user     => $rabbit_user,
      rabbit_password => $rabbit_password,
      rabbit_host     => $rabbit_nodes,
      #      sql_connection  => $quantum_sql_connection,
      verbose         => $verbose,
      debug           => $verbose,
    }

    class { 'quantum::plugins::ovs':
      bridge_mappings     => ["physnet1:br-ex","physnet2:br-prv"],
      network_vlan_ranges => 'physnet1,physnet2:1000:2000',
      sql_connection      => $quantum_sql_connection,
      tenant_network_type => $tenant_network_type,
      enable_tunneling    => $enable_tunneling,
    }

    class { 'quantum::agents::ovs':
      bridge_uplinks   => ["br-ex:${public_interface}","br-prv:${private_interface}"],
      bridge_mappings  => ['physnet1:br-ex', 'physnet2:br-prv'],
      enable_tunneling => $enable_tunneling,
      local_ip         => $internal_address,
    }

    class { 'quantum::agents::dhcp':
      debug          => True,
      use_namespaces => False,
    }
    class { 'quantum::agents::l3':
      #enabled             => $quantum_l3_enable,
      debug               => True,
      fixed_range         => $fixed_range,
      floating_range      => $floating_range,
      tenant_network_type => $tenant_network_type,
      create_networks     => $create_networks,
      auth_url            => "http://${auth_host}:35357/v2.0",
      auth_tenant         => 'services',
      auth_user           => 'quantum',
      auth_password       => $quantum_user_password,
      use_namespaces      => False,
      metadata_ip         => $service_endpoint,
    }


}
