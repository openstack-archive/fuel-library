#
# Use Case: Provider Router with Private Networks
#
define quantum::network::provider_router (
  $tenant_name    = 'admin',
  $router_subnets = undef,
  $router_extnet  = undef,
  $router_state   = undef,
) {

  Quantum_subnet<||> -> Quantum_router<||>

  # create router
  quantum_router { $title:
    ensure      => present,
    tenant      => $tenant_name,
    int_subnets => $router_subnets,
    ext_net     => $router_extnet,
    #admin_state => $admin_state,
  } 

}
