require File.join File.dirname(__FILE__), '../pacemaker_common'

Puppet::Type.type(:cs_location).provide(:pacemaker, :parent => Puppet::Provider::Pacemaker_common) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive colocations on the system; add, delete, or adjust various
        aspects.'

  commands :cibadmin => 'cibadmin'
  commands :crm_attribute => 'crm_attribute'
  commands :crm_node => 'crm_node'
  commands :crm_resource => 'crm_resource'
  commands :crm_attribute => 'crm_attribute'

  #TODO date_expressions
  #TODO instances
  #TODO prefetch
  #TODO fail if there is no primitive
  #TODO rules format/validation

  attr_accessor :property_hash
  attr_accessor :resource

  def retrieve_data
    data = constraint_locations.fetch resource[:name], {}
    self.property_hash = {
        :name => resource[:name],
        :ensure => :present,
    }
    self.property_hash[:primitive] = data['rsc'] if data['rsc']
    self.property_hash[:node_name] = data['node'] if data['node']
    self.property_hash[:node_score] = data['score'] if data['score']
    self.property_hash[:rules] = data['rules'] if data['rules']
  end

  def exists?
    debug "Call: exists? on '#{resource}'"
    out = constraint_locations.key? resource[:name]
    retrieve_data
    debug "Return: #{out}"
    out
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    debug "Call: create on '#{resource}'"
    self.property_hash = {
        :name => resource[:name],
        :ensure => :present,
        :primitive => resource[:primitive],
        :node_name => resource[:node_name],
        :node_score => resource[:node_score],
        :rules => resource[:rules],
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug "Call: destroy on '#{resource}'"
    cibadmin_remove "<rsc_location id='#{resource[:name]}'/>"
    property_hash.clear
    cluster_debug_report "#{resource} destroy"
  end

  # Getter that obtains the primitives array for us that should have
  # been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def primitive
    property_hash[:primitive]
  end

  # Getter that obtains the our score that should have been populated by
  # prefetch or instances (depends on if your using puppet resource or not).
  def node_score
    property_hash[:node_score]
  end

  def rules
    property_hash[:rules]
  end

  def node_name
    property_hash[:node_name]
  end

  # Our setters for the primitives array and score.  Setters are used when the
  # resource already exists so we just update the current value in the property
  # hash and doing this marks it to be flushed.
  def rules=(should)
    property_hash[:rules] = should
  end

  def primitives=(should)
    property_hash[:primitive] = should
  end

  def node_score=(should)
    property_hash[:node_score] = should
  end

  def node_name=(should)
    property_hash[:node_name] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
    debug "Call: flush on '#{resource}'"
    return if property_hash.empty?
    return unless property_hash[:name]
    return unless property_hash[:ensure] == :present

    location_structure = {}
    location_structure['id'] = property_hash[:name]
    location_structure['rsc'] = property_hash[:primitive]
    location_structure['score'] = property_hash[:node_score] if property_hash[:node_score]
    location_structure['node'] = property_hash[:node_name] if property_hash[:node_name]
    location_structure['rules'] = property_hash[:rules] if property_hash[:rules]

    unless location_structure['id'] and location_structure['rsc'] and
        location_structure['rules'] or
        (location_structure['score'] and location_structure['node'])
      fail "Data does not conatin all the required fields #{location_structure.inspect} at '#{resource}'"
    end

    location_patch = xml_document %w(diff diff-added cib configuration constraints)
    location_element = xml_rsc_location location_structure
    fail "Could not create XML patch for '#{resource}'" unless location_element
    location_patch.add_element location_element
    cibadmin_apply_patch xml_pretty_format location_patch.root
    cluster_debug_report "#{resource} flush"
  end
end
