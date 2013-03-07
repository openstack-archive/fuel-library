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
  
  newparam(:auth_user)  do
      desc "User credentials"
  end

  newparam(:auth_tenant)  do
        desc "User credentials"
    end

  newparam(:auth_password)  do
        desc "User credentials"
    end

  newparam(:auth_url)  do
        desc "User credentials"
    end

  def generate
    begin
        router_info = quantum('--os-tenant-name', @auth_tenant, '--os-username', @auth_user, '--os-password', @auth_password, '--os-auth-url', @auth_url, 'router-show', @name)
        router_row = router_info.split("\n").grep(/\bid/).to_s
        router_id = router_row.split('|')[2].strip if !router_row.empty?
        if defined? router_id and !router_id.to_s.empty?
            options = { :name => 'DEFAULT/router_id', :value => router_id }
            Puppet.notice("generating router_id ini setting")
            [ Puppet::Type.type(:quantum_l3_agent_config).new(options) ]
        end
    rescue
        # pass
    end
  end

  # Require the Quantum service to be running
  autorequire(:package) do
    ['python-quantumclient']
  end

end
