require File.join File.dirname(__FILE__), '../pacemaker_common'

Puppet::Type.type(:cs_commit).provide(:pacemaker, :parent => Puppet::Provider::Pacemaker_common) do

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
