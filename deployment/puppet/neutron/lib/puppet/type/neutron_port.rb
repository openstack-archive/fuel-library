Puppet::Type.newtype(:neutron_port) do
  desc <<-EOT
    This is currently used to model the creation of neutron ports.

    Ports are used when associating a network and a router interface.
  EOT

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Symbolic name for the port'
    newvalues(/.*/)
  end

  newproperty(:id) do
    desc 'The unique id of the port'
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

  newproperty(:network_name) do
    desc <<-EOT
      The name of the network that this port is assigned to on creation.
    EOT
  end

  newproperty(:network_id) do
    desc <<-EOT
      The uuid of the network that this port is assigned to on creation.
    EOT
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newproperty(:subnet_name) do
    desc 'A subnet to which the port is assigned on creation.'
  end

  newproperty(:subnet_id) do
    desc <<-EOT
      The uuid of the subnet on which this ports ip exists.
    EOT
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newproperty(:ip_address) do
    desc 'A static ip address given to the port on creation.'
  end

  newproperty(:status) do
    desc 'Whether the port is currently operational or not.'
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newparam(:tenant_name) do
    desc 'The name of the tenant which will own the port.'
  end

  newproperty(:tenant_id) do
    desc 'A uuid identifying the tenant which will own the port.'
  end

  autorequire(:service) do
    ['neutron-server']
  end

  autorequire(:keystone_tenant) do
    [self[:tenant_name]] if self[:tenant_name]
  end

  autorequire(:neutron_network) do
    [self[:name]]
  end

  validate do
    if self[:tenant_id] && self[:tenant_name]
      raise(Puppet::Error, 'Please provide a value for only one of tenant_name and tenant_id.')
    end
    if self[:ip_address] && self[:subnet_name]
      raise(Puppet::Error, 'Please provide a value for only one of ip_address and subnet_name.')
    end
  end

end
