require File.join(File.dirname(__FILE__), 'l2_base')

class Puppet::Provider::Ovs_base < Puppet::Provider::L2_base

  def vendor_specific
    return {}
  end
  def vendor_specific=(value)
    fail("Resource '#{@resource[:name]}': Vendor_specific field don't implemented for default providers.")
  end

end
# vim: set ts=2 sw=2 et :