module Puppet
  Puppet::Type.newtype(:ovs_port) do
    @doc = "A Virtual Switch Port"

    ensurable

    newparam(:interface) do
      isnamevar
      desc "The interface to attach to the bridge"
    end

    newparam(:bridge) do
      desc "What bridge to use"
    end

    autorequire(:ovs_bridge) do
      [self[:bridge]]
    end

  end
end

