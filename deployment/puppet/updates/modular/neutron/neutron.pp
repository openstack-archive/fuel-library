$role = hiera('role', undef)

if $role in ['contoller', 'primary-cointroller'] {
  class { 'updates::neutron::server' :}

  class { 'updates::neutron::ovs_agent' :
    pacemaker => true,
  }
}

if $role == 'compute' {
  class { 'updates::neutron::ovs_agent' :}
}
