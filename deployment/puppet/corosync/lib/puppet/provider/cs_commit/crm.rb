require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'crmsh'

Puppet::Type.type(:cs_commit).provide(:crm, :parent => Puppet::Provider::Crmsh) do
  commands :crm => 'crm'

  def self.instances
    block_until_ready
    []
  end

  def sync(cib)
    crm('cib', 'commit', cib)
  end
end
