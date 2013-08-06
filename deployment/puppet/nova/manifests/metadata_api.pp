#
class nova::metadata_api (
  $enabled           = true,
  $ensure_package    = 'present',
  $auth_strategy     = 'keystone',
  $admin_auth_url    = 'http://127.0.0.1:35357/v2.0',
  $admin_tenant_name = 'services',
  $admin_user        = 'nova',
  $auth_password     = 'quantum_pass',
  $service_endpoint  = '127.0.0.1',
  $listen_ip         = '0.0.0.0',
  $controller_nodes  = ['127.0.0.1'],
  $rpc_backend       = 'nova.rpc.impl_kombu',
  $queue_provider    = 'rabbitmq',
  $rabbit_user       = 'rabbit_user',
  $rabbit_password   = 'rabbit_password',
  $rabbit_ha_virtual_ip= false,
  $qpid_user         = 'nova',
  $qpid_password     = 'qpid_pw',
  $qpid_node        = false,
  $quantum_netnode_on_cnt= false,
) {

  include nova::params

  nova::generic_service { 'metadata-api':
    enabled        => true,
    package_name   => $::nova::params::meta_api_package_name,
    service_name   => $::nova::params::meta_api_service_name,
  }
  Package[$::nova::params::meta_api_package_name] -> Nova_config<||>
  Nova_config<||> ~> Service[$::nova::params::meta_api_service_name]

  case $queue_provider {
    'rabbitmq': {
      if $rabbit_ha_virtual_ip {
        $rabbit_hosts = "${rabbit_ha_virtual_ip}:5672"
      } else {
        $rabbit_hosts = join(regsubst($controller_nodes, '$', ':5672'), ',')
      }
      nova_config {
        'DEFAULT/rabbit_hosts':              value => $rabbit_hosts;
        'DEFAULT/rabbit_userid':             value => $rabbit_user;
        'DEFAULT/rabbit_password':           value => $rabbit_password;
        'DEFAULT/rpc_backend':               value => $rpc_backend;
        'DEFAULT/rabbit_virtual_host':       value => '/';
      }
    }
    'qpid': {
      if $qpid_node {
        $qpid_hosts = "${qpid_node}:5672"
      } else {
        $qpid_hosts = join(regsubst($controller_nodes, '$', ':5672'), ',')
      }
      nova_config {
        'DEFAULT/qpid_hosts':              value => $qpid_hosts;
        'DEFAULT/qpid_username':             value => $qpid_user;
        'DEFAULT/qpid_password':           value => $qpid_password;
        'DEFAULT/rpc_backend':             value => 'nova.rpc.impl_qpid';
      }
    }
  }

  $memcached_servers = join(regsubst($controller_nodes, '$', ':11211'), ',')

  nova_config {'DEFAULT/quantum_connection_host':   value => $service_endpoint }

  if !defined(Nova_config['DEFAULT/sql_connection']) {
    nova_config {'DEFAULT/sql_connection': value => "mysql://nova:nova@${service_endpoint}/nova";}
  }
  #if ! $quantum_netnode_on_cnt {
    nova_config {
      'DEFAULT/quantum_auth_strategy':     value => $auth_strategy;
      'DEFAULT/quantum_admin_auth_url':    value => $admin_auth_url;
      'DEFAULT/quantum_admin_password':    value => $auth_password;
      'DEFAULT/quantum_admin_username':    value => 'quantum';
      'DEFAULT/quantum_admin_tenant_name': value => $admin_tenant_name;
      'DEFAULT/quantum_url':               value => "http://${service_endpoint}:9696" ;
      'DEFAULT/metadata_listen':           value => $listen_ip;
      'DEFAULT/auth_strategy':             value => $auth_strategy;
      'DEFAULT/memcached_servers':         value => $memcached_servers;
      'DEFAULT/network_api_class':         value => 'nova.network.quantumv2.api.API';
      'DEFAULT/rootwrap_config':           value => '/etc/nova/rootwrap.conf';
      'DEFAULT/rabbit_ha_queues':          value => 'True';
    }
  #}
}
