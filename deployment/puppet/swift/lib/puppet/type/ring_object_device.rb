Puppet::Type.newtype(:ring_object_device) do
  require 'ipaddr'

  ensurable

  newparam(:name, :namevar => true) do
    validate do |value|
      address = value.split(':')
      raise(Puppet::Error, "invalid name #{value}, should contain address:port/device") unless address.size == 2
      port_device = address[1].split('/')
      raise(Puppet::Error, "namevar should contain a device") unless port_device.size == 2
      IPAddr.new(address[0])
    end
  end

  newproperty(:zone)

  newproperty(:weight) do
    munge do |value|
      "%.2f" % value
    end
  end

  newproperty(:meta)

  [:id, :partitions, :balance].each do |param|
    newproperty(param) do
      validate do |value|
        raise(Puppet::Error, "#{param} is a read only property, cannot be assigned")
      end
    end
  end

end
