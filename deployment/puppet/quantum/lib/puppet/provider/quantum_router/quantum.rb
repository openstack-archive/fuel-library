# Load the Quantum provider library to help
require File.join(File.dirname(__FILE__), '..','..','..', 'puppet/provider/quantum')

Puppet::Type.type(:quantum_router).provide(
  :quantum,
  :parent => Puppet::Provider::Quantum
) do

  desc "Manage quantum router"

  optional_commands :quantum  => 'quantum'
  optional_commands :keystone => 'keystone'
  optional_commands :sleep => 'sleep'

  # I need to setup caching and what-not to make this lookup performance not suck
  def self.instances
    router_list = auth_quantum("router-list")
    return [] if router_list.chomp.empty?

    router_list.split("\n")[3..-2].collect do |net|
      new(:name => net.split[3])
    end
  end

  def self.tenant_id
    @tenant_id ||= get_tenants_id
  end

  def tenant_id
    self.class.tenant_id
  end


  def create
    admin_state = []

    if @resource[:admin_state] and @resource[:admin_state].downcase == 'down'
      admin_state.push('--admin-state-down')
    end

    sleep(5) #todo: check avalability Quantum API and waiting it.

    router_info = auth_quantum('router-create',
      '--tenant_id', tenant_id[@resource[:tenant]],
      admin_state,
      @resource[:name]
    )

    # notice("ROUTER: #{router_info}")

    # add an internal networks interfaces to a router
    @resource[:int_subnets].each do |subnet|
      auth_quantum('router-interface-add',
        @resource[:name],
        subnet
      )
    end

    #Set an gateway interface to the specified external network
    if @resource[:ext_net]
      auth_quantum('router-gateway-set',
        @resource[:name],
        @resource[:ext_net]
      )

      # update router_id option
      # router_id = self.class.get_id(router_info)
      # ql3a_conf = Puppet::Type.type(:quantum_l3_agent_config).new(:name => "DEFAULT/router_id", :value => router_id)
      # ql3a_conf.provider.create
    end
  end

  def exists?
    begin
      router_list = auth_quantum("router-list")
      return router_list.split("\n")[3..-2].detect do |router|
        router.split[3] == @resource[:name]
      end
    rescue
      return false
    end
  end

  def destroy
    auth_quantum("router-delete", @resource[:name])
  end

  private
    def self.get_id(router_info)
      router_info.split("\n").grep(/\bid/).to_s.split[3]
    end

    def self.get_tenants_id
      # notice("*** GET_TENANT_ID")
      list_keystone_tenants
    end

end
