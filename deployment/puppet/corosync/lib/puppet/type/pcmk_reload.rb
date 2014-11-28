module Puppet
  newtype(:pcmk_reload) do
    desc 'Kill and restart corosync on DC if this node is not online'

    newparam(:name) do
      isnamevar
    end

    newproperty(:status) do
      newvalues :online, :offline
      defaultto :online
    end

    newparam(:reload) do
      newvalues :dc, :all
      defaultto :all
    end

    autorequire(:service) do
      [ 'corosync' ]
    end
  end
end
