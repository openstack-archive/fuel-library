Puppet::Type.newtype(:neutron_subnet) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Symbolic name for the subnet'
    newvalues(/.*/)
  end

  newproperty(:id) do
    desc 'The unique id of the subnet'
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newproperty(:cidr) do
    desc 'CIDR representing IP range for this subnet, based on IP version'
  end

  newproperty(:ip_version) do
    desc 'The IP version of the CIDR'
    newvalues('4', '6')
  end

  newproperty(:allocation_pools, :array_matching => :all) do
    desc <<-EOT
    Array of Sub-ranges of cidr available for dynamic allocation to ports.
    Syntax:["start=IPADDR,end=IPADDR", ...]
    EOT
  end

  newproperty(:gateway_ip) do
    desc <<-EOT
    The default gateway provided by DHCP to devices in this subnet.  If set to
    '' then no gateway IP address will be provided via DHCP.
    EOT
  end

  newproperty(:enable_dhcp) do
    desc 'Whether DHCP is enabled for this subnet or not.'
    newvalues(/(t|T)rue/, /(f|F)alse/)
    munge do |v|
      v.to_s.capitalize
    end
  end

  newproperty(:host_routes, :array_matching => :all) do
    desc <<-EOT
    Array of routes that should be used by devices with IPs from this subnet
    (not including local subnet route).
    Syntax:["destination=CIDR,nexhop=IP_ADDR", ...]
    EOT
  end

  newproperty(:dns_nameservers, :array_matching => :all) do
    desc <<-EOT
    'Array of DNS name servers used by hosts in this subnet.'
    EOT
  end

  newproperty(:network_id) do
    desc 'A uuid identifying the network this subnet is associated with.'
  end

  newparam(:network_name) do
    desc 'The name of the network this subnet is associated with.'
  end

  newparam(:tenant_name) do
    desc 'The name of the tenant which will own the subnet.'
  end

  newproperty(:tenant_id) do
    desc 'A uuid identifying the tenant which will own the subnet.'
  end

  autorequire(:service) do
    ['neutron-server']
  end

  autorequire(:keystone_tenant) do
    [self[:tenant_name]] if self[:tenant_name]
  end

  autorequire(:neutron_network) do
    [self[:network_name]] if self[:network_name]
  end

  validate do
    if self[:ensure] != :present
      return
    end
    if ! self[:cidr]
      raise(Puppet::Error, 'Please provide a valid CIDR')
    elsif ! (self[:network_id] || self[:network_name])
      raise(Puppet::Error, <<-EOT
A value for one of network_name or network_id must be provided.
EOT
            )
    elsif self[:network_id] && self[:network_name]
      raise(Puppet::Error, <<-EOT
Please provide a value for only one of network_name and network_id.
EOT
            )
    elsif self[:tenant_id] && self[:tenant_name]
      raise(Puppet::Error, <<-EOT
Please provide a value for only one of tenant_name and tenant_id.
EOT
            )
    end
  end

end
