#
# Use Case: Provider Router with Private Networks
#
define quantum::network::provider_router (
  $tenant_name    = 'admin',
  $auth_tenant = 'admin',
  $auth_user = 'quantum',
  $auth_password = 'quantum_pass',
  $auth_url = 'http://127.0.0.1:5000/v2.0/',
  $router_subnets = undef,
  $router_extnet  = undef,
  $router_state   = undef,) {
  Quantum_subnet <| |> -> Quantum_router <| |>
  Service <| title == 'keystone' |> -> Quantum_router <| |>

  # create router
  quantum_router { $title:
    ensure      => present,
    tenant      => $tenant_name,
    int_subnets => $router_subnets,
    ext_net     => $router_extnet,
    auth_url => $auth_url,
    auth_user => $auth_user,
    auth_password => $auth_password,
    auth_tenant => $auth_tenant,
  # admin_state => $admin_state,
  }

}
