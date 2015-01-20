require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'crmsh'

Puppet::Type.type(:cs_shadow).provide(:crm, :parent => Puppet::Provider::Crmsh) do
  commands :crm => 'crm'

  def self.instances
    block_until_ready
    []
  end

  def sync(cib)
    begin
      crm('cib', 'delete', cib)
    rescue => e
      # If the CIB doesn't exist, we don't care.
    end
    crm('cib', 'new', cib)
  end
end
