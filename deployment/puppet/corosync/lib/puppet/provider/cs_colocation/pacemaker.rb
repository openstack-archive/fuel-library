require File.join File.dirname(__FILE__), '../pacemaker_common'

Puppet::Type.type(:cs_colocation).provide(:pacemaker, :parent => Puppet::Provider::Pacemaker_common) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive colocations on the system; add, delete, or adjust various
        aspects.'

  commands :cibadmin => 'cibadmin'
  commands :crm_attribute => 'crm_attribute'
  commands :crm_node => 'crm_node'
  commands :crm_resource => 'crm_resource'
  commands :crm_attribute => 'crm_attribute'

  #TODO instances
  #TODO prefetch
  #TODO fail if there is no primitive

  attr_accessor :property_hash
  attr_accessor :resource

  def retrieve_data
    data = constraint_colocations.fetch resource[:name], {}
    self.property_hash = {
        :name => resource[:name],
        :ensure => :present,
    }
    self.property_hash[:primitives] = [data['rsc'], data['with-rsc']] if data['rsc'] and data['with-rsc']
    self.property_hash[:score] = data['score'] if data['score']
  end

  def exists?
    debug "Call: exists? on '#{resource}'"
    out = constraint_colocations.key? resource[:name]
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
        :primitives => resource[:primitives],
        :score => resource[:score],
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug "Call: destroy on '#{resource}'"
    cibadmin_remove "<rsc_colocation id='#{resource[:name]}'/>"
    property_hash.clear
    cluster_debug_report "#{resource} destroy"
  end

  # Getter that obtains the primitives array for us that should have
  # been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def primitives
    property_hash[:primitives]
  end

  # Getter that obtains the our score that should have been populated by
  # prefetch or instances (depends on if your using puppet resource or not).
  def score
    property_hash[:score]
  end

  # Our setters for the primitives array and score.  Setters are used when the
  # resource already exists so we just update the current value in the property
  # hash and doing this marks it to be flushed.
  def primitives=(should)
    property_hash[:primitives] = should
  end

  def score=(should)
    property_hash[:score] = should
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

    colocation_structure = {}
    colocation_structure['id'] = property_hash[:name]
    colocation_structure['score'] = property_hash[:score]
    colocation_structure['rsc'] = property_hash[:primitives][0]
    colocation_structure['with-rsc'] = property_hash[:primitives][1]

    unless colocation_structure['id'] and colocation_structure['score'] and
        colocation_structure['rsc'] and colocation_structure['with-rsc']
      fail "Data does not conatin all the required fields #{colocation_structure.inspect} at '#{resource}'"
    end

    colocation_patch = xml_document %w(diff diff-added cib configuration constraints)
    colocation_element = xml_rsc_colocation colocation_structure
    fail "Could not create XML patch for '#{resource}'" unless colocation_element
    colocation_patch.add_element colocation_element
    cibadmin_apply_patch xml_pretty_format colocation_patch.root
    cluster_debug_report "#{resource} flush"
  end
end
