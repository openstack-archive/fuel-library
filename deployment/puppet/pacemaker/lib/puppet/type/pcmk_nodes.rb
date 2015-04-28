module Puppet
  newtype(:pcmk_nodes) do
    desc %q(Add and remove cluster nodes)

    newparam(:name) do
      isnamevar
    end

    newparam(:use_cmapctl) do
      defaultto true
    end

    newparam(:nodes, :array_matching => :all) do
      validate do |value|
        fail 'Nodes should be a non-empty array!' unless value.is_a? Array and value.any?
      end
    end

    newproperty(:corosync_nodes, :array_matching => :all) do
      defaultto { @resource[:nodes] }
    end

    newproperty(:pacemaker_nodes, :array_matching => :all) do
      defaultto { @resource[:nodes] }
    end

    newproperty(:pacemaker_nodes_states, :array_matching => :all) do
      defaultto { @resource[:nodes] }
    end

  end
end

