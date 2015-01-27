require File.join(File.dirname(__FILE__), 'l2_base')

class Puppet::Provider::Lnx_base < Puppet::Provider::L2_base

  def external_ids
    return ""
  end
  def external_ids=(value)
    #fail("Resource '#{@resource[:name]}': External_ids feature don't implemented for this provider.")
  end

  def vendor_specific
    return {}
  end
  def vendor_specific=(value)
    fail("Resource '#{@resource[:name]}': Vendor_specific field don't implemented for default providers.")
  end

  def type
    :absent
  end
  def type=(value)
    debug("Resource '#{@resource[:name]}': Don't support interface type change.")
  end

end
# vim: set ts=2 sw=2 et :