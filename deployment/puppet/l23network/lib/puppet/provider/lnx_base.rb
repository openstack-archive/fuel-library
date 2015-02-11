require File.join(File.dirname(__FILE__), 'l2_base')

class Puppet::Provider::Lnx_base < Puppet::Provider::L2_base

  def vendor_specific
    @property_hash[:vendor_specific] || :absent
  end
  def vendor_specific=(val)
    nil
  end

end
# vim: set ts=2 sw=2 et :