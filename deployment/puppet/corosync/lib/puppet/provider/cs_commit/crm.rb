require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'corosync'

Puppet::Type.type(:cs_commit).provide(:crm, :parent => Puppet::Provider::Corosync) do
  commands :crm => 'crm'
  commands :crm_attribute => 'crm_attribute'

  def self.instances
    block_until_ready
    []
  end

  def sync(cib)
    crm('cib', 'commit', cib)
  end
end
