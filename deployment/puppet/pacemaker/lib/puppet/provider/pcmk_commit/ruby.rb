require File.join File.dirname(__FILE__), '../pacemaker.rb'

Puppet::Type.type(:pcmk_commit).provide(:ruby, :parent => Puppet::Provider::Pacemaker) do

  commands :cibadmin => 'cibadmin'
  commands :crm_attribute => 'crm_attribute'
  commands :crm_node => 'crm_node'
  commands :crm_resource => 'crm_resource'
  commands :crm_attribute => 'crm_attribute'
  commands :crm_shadow => 'crm_shadow'

  def sync(cib)
    wait_for_online
    retry_block {
      crm_shadow '--force', '--commit', cib
    }
  end

end
