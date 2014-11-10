require File.join File.dirname(__FILE__), '../pacemaker_common'

Puppet::Type.type(:cs_order).provide(:pacemaker, :parent => Puppet::Provider::Pacemaker_common) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived. This provider will check the state
        of current primitive start orders on the system; add, delete, or adjust various
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
    data = constraint_orders.fetch resource[:name], {}
    self.property_hash = {
        :name => resource[:name],
        :ensure => :present,
    }
    self.property_hash[:first] = data['first'] if data['first']
    self.property_hash[:second] = data['then'] if data['then']
    self.property_hash[:score] = data['score'] if data['score']
  end

  def exists?
    debug "Call: exists? on '#{resource}'"
    out = constraint_orders.key? resource[:name]
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
        :first => resource[:first],
        :second => resource[:second],
        :score => resource[:score],
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug "Call: destroy on '#{resource}'"
    cibadmin_remove "<rsc_order id='#{resource[:name]}'/>"
    property_hash.clear
    cluster_debug_report "#{resource} destroy"
  end

  # Getters that obtains the first and second primitives and score in our
  # ordering definintion that have been populated by prefetch or instances
  # (depends on if your using puppet resource or not).
  def first
    property_hash[:first]
  end

  def second
    property_hash[:second]
  end

  def score
    property_hash[:score]
  end

  # Our setters for the first and second primitives and score.  Setters are
  # used when the resource already exists so we just update the current value
  # in the property hash and doing this marks it to be flushed.
  def first=(should)
    property_hash[:first] = should
  end

  def second=(should)
    property_hash[:second] = should
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

    order_structure = {}
    order_structure['id'] = property_hash[:name]
    order_structure['score'] = property_hash[:score]
    order_structure['first'] = property_hash[:first]
    order_structure['then'] = property_hash[:second]

    unless order_structure['id'] and order_structure['score'] and
        order_structure['first'] and order_structure['then']
      fail "Data does not conatin all the required fields #{order_structure.inspect} at '#{resource}'"
    end

    order_patch = xml_document %w(diff diff-added cib configuration constraints)
    order_element = xml_rsc_order order_structure
    fail "Could not create XML patch for '#{resource}'" unless order_element
    order_patch.add_element order_element
    cibadmin_apply_patch xml_pretty_format order_patch.root
    cluster_debug_report "#{resource} flush"
  end
end
