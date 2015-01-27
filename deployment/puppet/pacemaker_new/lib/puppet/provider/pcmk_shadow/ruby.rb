require File.join File.dirname(__FILE__), '../pacemaker.rb'

Puppet::Type.type(:pcmk_shadow).provide(:ruby, :parent => Puppet::Provider::Pacemaker) do

  commands :cibadmin => 'cibadmin'
  commands :crm_attribute => 'crm_attribute'
  commands :crm_node => 'crm_node'
  commands :crm_resource => 'crm_resource'
  commands :crm_attribute => 'crm_attribute'
  commands :crm_shadow => 'crm_shadow'

  #TODO instances
  #TODO prefetch

  attr_accessor :property_hash
  attr_accessor :resource

  def sync(cib)
    wait_for_online

    retry_options = {
        :retry_count => 1,
        :retry_step => 0,
        :retry_fail_on_timeout => false,
    }

    retry_block(retry_options) {
      crm_shadow '--force', '--delete', cib
    }

    retry_block(retry_options) {
      if @resource[:isempty] == :true
        crm_shadow '--force', '--create-empty', cib
      else
        crm_shadow '--force', '--create', cib
      end
    }
  end

end
