# Load the Neutron provider library to help
require File.join(File.dirname(__FILE__), '..','..','..', 'puppet/provider/neutron')

Puppet::Type.type(:neutron_subnet).provide(
  :neutron,
  :parent => Puppet::Provider::Neutron
) do

  desc "Manage neutron subnet/networks"

  optional_commands :neutron  => 'neutron'
  optional_commands :keystone => 'keystone'

  # I need to setup caching and what-not to make this lookup performance not suck
  def self.instances
    network_list = auth_neutron("subnet-list")
    if network_list.nil?
      raise(Puppet::ExecutionFailure, "Can't prefetch subnet-list. Neutron or Keystone API not availaible.")
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
    # tenant_subnet_id=$(get_id neutron subnet-create --tenant_id $tenant_id --ip_version 4 $tenant_net_id $fixed_range --gateway $network_gateway)
    # neutron subnet-create --tenant-id $tenant --name subnet01 net01 192.168.101.0/24
    # neutron subnet-create --tenant-id $tenant --name pub_subnet01 --gateway 10.0.1.254 public01 10.0.1.0/24 --enable_dhcp False

# --allocation-pool start=$pool_floating_start,end=$pool_floating_end
# --dns_nameservers list=true 8.8.8.8
    ip_opts = []
    {
      :ip_version => '--ip-version',
      :gateway    => '--gateway',
      :alloc_pool => '--allocation-pool',
    }.each do |param, opt|
      if @resource[param]
        ip_opts.push(opt).push(@resource[param])
      end
    end

    proto_opts = []
    {
      :enable_dhcp => '--enable_dhcp',
      :nameservers => ['--dns_nameservers', 'list=true']
    }.each do |param, opt|
      if @resource[param]
        proto_opts.push(opt).push(@resource[param])
      end
    end

    auth_neutron('subnet-create',
      '--tenant-id', tenant_id[@resource[:tenant]],
      '--name', @resource[:name],
      ip_opts,
      @resource[:network],
      @resource[:cidr],
      '--', proto_opts
    )
  end

  def destroy
    auth_neutron("subnet-delete", @resource[:name])
  end

  private
    def self.get_id(subnet_info)
      # ruby 1.8.x specific
      subnet_info.grep(/ id /).to_s.split[3]
    end

    def self.get_tenants_id
      # notice("*** GET_TENANT_ID")
      list_keystone_tenants
    end

end
