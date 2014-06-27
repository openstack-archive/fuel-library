Puppet::Type.newtype(:neutron_router) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Symbolic name for the router'
    newvalues(/.*/)
  end

  newproperty(:id) do
    desc 'The unique id of the router'
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newproperty(:admin_state_up) do
    desc 'The administrative status of the router'
    newvalues(/(t|T)rue/, /(f|F)alse/)
    munge do |v|
      v.to_s.capitalize
    end
  end

  newproperty(:external_gateway_info) do
    desc <<-EOT
      External network that this router connects to for gateway services
      (e.g., NAT).
    EOT
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newproperty(:gateway_network_name) do
    desc <<-EOT
      The name of the external network that this router connects to
      for gateway services (e.g. NAT).
    EOT
  end

  newproperty(:gateway_network_id) do
    desc <<-EOT
      The uuid of the external network that this router connects to
      for gateway services (e.g. NAT).
    EOT
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newproperty(:status) do
    desc 'Whether the router is currently operational or not.'
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newparam(:tenant_name) do
    desc 'The name of the tenant which will own the router.'
  end

  newproperty(:tenant_id) do
    desc 'A uuid identifying the tenant which will own the router.'
  end

  autorequire(:service) do
    ['neutron-server']
  end

  autorequire(:keystone_tenant) do
    [self[:tenant_name]] if self[:tenant_name]
  end

  autorequire(:neutron_network) do
    [self[:gateway_network_name]] if self[:gateway_network_name]
  end

  validate do
    if self[:ensure] != :present
      return
    end
    if self[:tenant_id] && self[:tenant_name]
      raise(Puppet::Error, <<-EOT
Please provide a value for only one of tenant_name and tenant_id.
EOT
            )
    end
  end

end
