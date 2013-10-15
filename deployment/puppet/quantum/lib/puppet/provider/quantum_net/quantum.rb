# Load the Quantum provider library to help
require File.join(File.dirname(__FILE__), '..','..','..', 'puppet/provider/quantum')

Puppet::Type.type(:quantum_net).provide(
  :quantum,
  :parent => Puppet::Provider::Quantum
) do

  desc "Manage quantum network"

  optional_commands :quantum  => 'quantum'
  optional_commands :keystone => 'keystone'
  optional_commands :sleep => 'sleep'

  # I need to setup caching and what-not to make this lookup performance not suck
  def self.instances
    network_list = auth_quantum("net-list")
    return [] if network_list.chomp.empty?

    network_list.split("\n")[3..-2].collect do |net|
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
    # quantum net-create --tenant_id $tenant_id $tenant_network_name --provider:network_type vlan --provider:physical_network physnet2 --provider:segmentation_id 501)
    # quantum net-create $ext_net_name -- --router:external=True --tenant_id $tenant_id --provider:network_type flat)
    optional_opts = []
    {
      :router_ext   => '--router:external',
      :network_type => '--provider:network_type',
      :physnet      => '--provider:physical_network',
      :segment_id   => '--provider:segmentation_id'
    }.each do |param, opt|
      if @resource[param]
        optional_opts.push(opt).push(@resource[param])
      end
    end
    if @resource[:shared] == 'True'
        optional_opts.push("--shared")
    end

    sleep(20) #todo: check avalability Quantum API and waiting it.

    auth_quantum('net-create',
      '--tenant_id', tenant_id[@resource[:tenant]],
      @resource[:name],
      optional_opts
    )
  end

  def exists?
    begin
      network_list = auth_quantum("net-list")
      return network_list.split("\n")[3..-2].detect do |net|
        # n =~ /^(\S+)\s+(#{@resource[:network].split('/').first})/
        net.split[3] == @resource[:name]
      end
    rescue
      return false
    end
  end

  def destroy
    auth_quantum("net-delete", @resource[:name])
  end

  private
    def self.get_id(net_info)
      # ruby 1.8.x specific
      net_info.grep(/ id /).to_s.split[3]
    end

    def self.get_tenants_id
      # notice("*** GET_TENANT_ID")
      list_keystone_tenants
    end

end
