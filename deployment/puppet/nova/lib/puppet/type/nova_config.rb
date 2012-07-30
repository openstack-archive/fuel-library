Puppet::Type.newtype(:nova_config) do

  def self.default_target
    "/etc/nova/nova.conf"
  end

  ensurable

  newparam(:name, :namevar => true) do
    newvalues(/^\S+$/)
  end

  newproperty(:value) do
    munge do |value|
      value.to_s
    end
    newvalues(/^[\S ]+$/)
  end

  newproperty(:target) do
    desc "Path to our nova config file"
    defaultto {
      Puppet::Type.type(:nova_config).default_target
    }
  end

  validate do
    if self[:ensure] == :present
      if self[:value].nil? || self[:value] == ''
        raise Puppet::Error, "Property value must be set for #{self[:name]} when ensure is present"
      end
    end
  end

end
