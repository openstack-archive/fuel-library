# VMWare related network configuration class
# It handles whether we use neutron or nova-network and call for an appropriate class

class vmware::network (

  $use_quantum = false,

)

{ # begin of class

  if $use_quantum { # for quantum
    class { 'vmware::network::neutron': }
  } else { # for nova network
    class { 'vmware::network::nova': }
  } # end of network check

} # end of class
