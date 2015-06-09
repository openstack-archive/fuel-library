Puppet::Type.type(:neutron_l3_ovs_bridge).provide(:neutron) do
  desc <<-EOT
    Neutron provider to manage neutron_l3_ovs_bridge type.

    The provider ensures that the gateway ip of the subnet is
    configured on the ovs bridge.
  EOT

  commands :ip => '/sbin/ip'

  mk_resource_methods

  def gateway_ip
    if @gateway_ip == nil
      subnet = Puppet::Type.type('neutron_subnet').instances.find do |instance|
        instance.provider.name == @resource[:subnet_name]
      end
      if subnet
        provider = subnet.provider
        @gateway_ip = "#{provider.gateway_ip}/#{provider.cidr.split('/')[1]}"
      else
        fail("Unable to find subnet for name #{@resource[:subnet_name]}")
      end
    end
    @gateway_ip
  end

  def bridge_ip_addresses
    addresses = []
    result = ip('addr', 'show', @resource[:name])
    (result.split("\n") || []).compact.each do |line|
      if match = line.match(/\sinet ([^\s]*) .*/)
        addresses << match.captures[0]
      end
    end
    return addresses
  end

  def exists?
    bridge_ip_addresses.include?(gateway_ip)
  end

  def create
    ip('addr', 'add', gateway_ip, 'dev', @resource[:name])
    ip('link', 'set', 'dev', @resource[:name], 'up')
    @property_hash[:ensure] = :present
  end

  def destroy
    ip('addr', 'del', gateway_ip, 'dev', @resource[:name])
    @property_hash[:ensure] = :absent
  end

end
