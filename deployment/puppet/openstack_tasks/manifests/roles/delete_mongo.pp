class openstack_tasks::roles::delete_mongo {

  notice('MODULAR: roles/delete_mongo.pp')

  prepare_network_config(hiera_hash('network_scheme', {}))
  $mongo_hash          = hiera_hash('mongo', {})
  $mongodb_port        = hiera('mongodb_port', '27017')
  $mongo_nodes         = get_nodes_hash_by_roles(hiera_hash('network_metadata'), hiera('mongo_roles'))
  $mongo_address_map   = get_node_to_ipaddr_map_by_network_role($mongo_nodes, 'mongo/db')
  $mongo_hosts         = suffix(values($mongo_address_map), ":${mongodb_port}")
  $bind_address        = get_network_role_property('mongo/db', 'ipaddr')
  $ceilometer_hash     = hiera_hash('ceilometer')
  $roles               = hiera('roles')
  $replset_name        = 'ceilometer'

  mongodb_replset { $replset_name:
    members => delete($mongo_hosts, "${bind_address}:${mongodb_port}")
  }
}
