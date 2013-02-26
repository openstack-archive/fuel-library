Puppet::Type.newtype(:quantum_router) do

  @doc = "Manage creation/deletion of quantum routers"

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The router name'
  end

  newparam(:tenant) do
    desc "The tenant that the router is associated with" 
    defaultto "admin"
  end

  newparam(:admin_state) do
    # defaultto "up"
  end

  newparam(:int_subnets) do
    desc "Add an internal networks interfaces to a router" 
    defaultto ""
  end

  newparam(:ext_net) do
    desc "Set an gateway interface to the specified external network" 
  end

#  def generate
#    router_info = self.provider.auth_quantum('router-show', @name)
#    router_id = router_info.split("\n").grep(/\bid/).to_s.split('|')[2].strip
#     options = { :name => 'DEFAULT/router_id', :value => router_id }
#     Puppet.notice("generating router_id ini setting")
#    [ Puppet::Type.type(:quantum_l3_agent_config).new(options) ]
#  end

  # Require the Quantum service to be running
  autorequire(:package) do
    ['python-quantumclient']
  end

end
