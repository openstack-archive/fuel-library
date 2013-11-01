# Load the Neutron provider library to help
require File.join(File.dirname(__FILE__), '..','..','..', 'puppet/provider/neutron')

Puppet::Type.type(:neutron_net).provide(
  :neutron,
  :parent => Puppet::Provider::Neutron
) do

  desc "Manage neutron network"

  optional_commands :neutron  => 'neutron'
  optional_commands :keystone => 'keystone'

  # I need to setup caching and what-not to make this lookup performance not suck
  def self.instances
    network_list = auth_neutron("net-list")
    if network_list.nil?
      raise(Puppet::ExecutionFailure, "Can't prefetch net-list. Neutron or Keystone API not availaible.")
    elsif network_list.chomp.empty?
      return []
    end

    network_list.split("\n")[3..-2].collect do |net|
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
    # neutron net-create --tenant_id $tenant_id $tenant_network_name --provider:network_type vlan --provider:physical_network physnet2 --provider:segmentation_id 501)
    # neutron net-create $ext_net_name -- --router:external=True --tenant_id $tenant_id --provider:network_type flat)
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

    auth_neutron('net-create',
      '--tenant_id', tenant_id[@resource[:tenant]],
      @resource[:name],
      optional_opts
    )
  end

  def destroy
    auth_neutron("net-delete", @resource[:name])
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
