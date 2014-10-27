# Load the Neutron provider library to help
require File.join(File.dirname(__FILE__), '..','..','..', 'puppet/provider/neutron')

Puppet::Type.type(:neutron_router).provide(
  :neutron,
  :parent => Puppet::Provider::Neutron
) do

  desc "Manage neutron router"

  optional_commands :neutron  => 'neutron'
  optional_commands :keystone => 'keystone'

  # I need to setup caching and what-not to make this lookup performance not suck
  def self.instances
    router_list = auth_neutron("router-list")
    if router_list.nil?
      raise(Puppet::ExecutionFailure, "Can't prefetch router-list. Neutron or Keystone API not availaible.")
    elsif router_list.chomp.empty?
      return []
    end

    router_list.split("\n")[3..-2].collect do |net|
      new(
        :name   => net.split[3],
        :ensure => :present
      )
    end
  end

  def exists?
    @property_hash[:ensure] == :present
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

    router_info = auth_neutron('router-create',
      '--tenant_id', tenant_id[@resource[:tenant]],
      admin_state,
      @resource[:name]
    )

    # notice("ROUTER: #{router_info}")

    # add an internal networks interfaces to a router
    @resource[:int_subnets].each do |subnet|
      auth_neutron('router-interface-add',
        @resource[:name],
        subnet
      )
    end

    #Set an gateway interface to the specified external network
    if @resource[:ext_net]
      auth_neutron('router-gateway-set',
        @resource[:name],
        @resource[:ext_net]
      )

      # update router_id option
      # router_id = self.class.get_id(router_info)
      # ql3a_conf = Puppet::Type.type(:neutron_l3_agent_config).new(:name => "DEFAULT/router_id", :value => router_id)
      # ql3a_conf.provider.create
    end
  end

  def destroy
    auth_neutron("router-delete", @resource[:name])
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
