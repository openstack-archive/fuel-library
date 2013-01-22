Puppet::Type.newtype(:ovs_port) do
    @doc = "Manage a Open vSwitch port"
    desc @doc

    ensurable

    newparam(:interface) do
      isnamevar
      desc "The interface to attach to the bridge"
    end

    newparam(:type) do
      newvalues('', :system, :internal, :tap, :gre, :ipsec_gre, :capwap, :patch, :null)
      defaultto('')
      desc "Ovs port type"
    end

    newparam(:skip_existing) do
      defaultto(false)
      desc "Allow skip existing port"
    end

    newparam(:bridge) do
      desc "What bridge to use"
    end

    autorequire(:ovs_bridge) do
      [self[:bridge]]
    end
end
