require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_shadow).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  commands :crm_shadow => 'crm_shadow'

  def self.instances
    block_until_ready
    []
  end

  def sync(cib)
    begin
      crm_shadow('--delete', cib)
    rescue => e
      # If the CIB doesn't exist, we don't care.
    end
    crm_shadow('--create', cib)
  end
end
