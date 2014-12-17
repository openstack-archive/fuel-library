# require 'csv'
# require 'puppet/util/inifile'

class Puppet::Provider::Ovs_base < Puppet::Provider

  def vendor_specific
    return {}
  end
  def vendor_specific=(value)
    fail("Resource '#{@resource[:name]}': Vendor_specific field don't implemented for default providers.")
  end

end