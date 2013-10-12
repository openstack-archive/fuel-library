# Load the Quantum provider library to help
require File.join(File.dirname(__FILE__), '..','..','..', 'puppet/provider/quantum')

Puppet::Type.type(:quantum_subnet).provide(
  :quantum,
  :parent => Puppet::Provider::Quantum
) do

  desc "Manage quantum subnet/networks"

  optional_commands :quantum  => 'quantum'
  optional_commands :keystone => 'keystone'

  # I need to setup caching and what-not to make this lookup performance not suck
  def self.instances
    network_list = auth_quantum("subnet-list")
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
    # tenant_subnet_id=$(get_id quantum subnet-create --tenant_id $tenant_id --ip_version 4 $tenant_net_id $fixed_range --gateway $network_gateway)
    # quantum subnet-create --tenant-id $tenant --name subnet01 net01 192.168.101.0/24
    # quantum subnet-create --tenant-id $tenant --name pub_subnet01 --gateway 10.0.1.254 public01 10.0.1.0/24 --enable_dhcp False

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

    auth_quantum('subnet-create',
      '--tenant-id', tenant_id[@resource[:tenant]],
      '--name', @resource[:name],
      ip_opts,
      @resource[:network],
      @resource[:cidr],
      '--', proto_opts
    )
  end

  def exists?
    begin
      network_list = auth_quantum("subnet-list")
      return network_list.split("\n")[3..-2].detect do |net|
        # n =~ /^(\S+)\s+(#{@resource[:network].split('/').first})/
        net.split[3] == @resource[:name]
      end
    rescue
      return false
    end
  end

  def destroy
    auth_quantum("subnet-delete", @resource[:name])
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
