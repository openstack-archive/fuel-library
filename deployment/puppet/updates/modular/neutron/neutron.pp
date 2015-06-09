$role = hiera('role', undef)

if $role in ['controller', 'primary-controller'] {
  class { 'updates::neutron::server' :}

  class { 'updates::neutron::ovs_agent' :
    pacemaker => true,
  }
}

if $role == 'compute' {
  class { 'updates::neutron::ovs_agent' :}
}
