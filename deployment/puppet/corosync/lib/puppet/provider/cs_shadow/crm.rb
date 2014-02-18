require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'corosync'

Puppet::Type.type(:cs_shadow).provide(:crm, :parent => Puppet::Provider::Corosync) do
  commands :crm => 'crm'
  commands :crm_attribute => 'crm_attribute'
  def self.instances
    block_until_ready
    []
  end

  def sync(cib)
    self.class.block_until_ready
    begin
      crm('cib', 'delete', cib)
    rescue => e
      # If the CIB doesn't exist, we don't care.
    end
    if @resource[:isempty] == :true
      crm('cib', 'new', cib, 'empty')
    else
      crm('cib', 'new', cib)
    end
  end
end
