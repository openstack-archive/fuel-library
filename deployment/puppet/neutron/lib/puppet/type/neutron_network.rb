Puppet::Type.newtype(:neutron_network) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Symbolic name for the network'
    newvalues(/.*/)
  end

  newproperty(:id) do
    desc 'The unique id of the network'
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newproperty(:admin_state_up) do
    desc 'The administrative status of the network'
    newvalues(/(t|T)rue/, /(f|F)alse/)
    munge do |v|
      v.to_s.capitalize
    end
  end

  newproperty(:shared) do
    desc 'Whether this network should be shared across all tenants or not'
    newvalues(/(t|T)rue/, /(f|F)alse/)
    munge do |v|
      v.to_s.capitalize
    end
  end

  newparam(:tenant_name) do
    desc 'The name of the tenant which will own the network.'
  end

  newproperty(:tenant_id) do
    desc 'A uuid identifying the tenant which will own the network.'
  end

  newproperty(:provider_network_type) do
    desc 'The physical mechanism by which the virtual network is realized.'
    newvalues(:flat, :vlan, :local, :gre)
  end

  newproperty(:provider_physical_network) do
    desc <<-EOT
      The name of the physical network over which the virtual network
      is realized for flat and VLAN networks.
    EOT
    newvalues(/\S+/)
  end

  newproperty(:provider_segmentation_id) do
    desc 'Identifies an isolated segment on the physical network.'
    munge do |v|
      Integer(v)
    end
  end

  newproperty(:router_external) do
    desc 'Whether this router will route traffic to an external network'
    newvalues(/(t|T)rue/, /(f|F)alse/)
    munge do |v|
      v.to_s.capitalize
    end
  end

  # Require the neutron-server service to be running
  autorequire(:service) do
    ['neutron-server']
  end

  autorequire(:keystone_tenant) do
    [self[:tenant_name]] if self[:tenant_name]
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
