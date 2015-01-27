require 'rexml/document'
require 'rexml/formatters/pretty'
require 'timeout'

# make rexml's attributes to be sorted by their name
# when iterating throuth them
# instead of randomly placing them each time
module REXML
  class Attributes
    def each_value # :yields: attribute
      keys.sort.each do |key|
        yield fetch key
      end
    end
  end
end

class Puppet::Provider::Pacemaker_common < Puppet::Provider

  def initialize(*args)
    cib_reset
    super
  end

  def pacemaker_options
    return @pacemaker_options if @pacemaker_options
    @pacemaker_options = {
        # how many times a command should retry if it's failing
        :retry_count => 360,
        # how long to wait between retries (seconds)
        :retry_step => 5,
        # how long to wait for a single commnand to finish running (seconds)
        :retry_timeout => 60,
        # count false or nil block return values as failures or only exceptions?
        :retry_false_is_failure => true,
        # raise error if no more retries left and command is still failing?
        :retry_fail_on_timeout => true,

        # what cluster properties should be shown on the debug status output
        :debug_show_properties => %w(symmetric-cluster no-quorum-policy),

        # how do we determine that the service have been started?
        # :global - The service is running on any node
        # :master - The service is running in the master mode on any node
        # :local  - The service is running on the local node
        :start_mode_multistate => :master,
        :start_mode_clone => :global,
        :start_mode_simple => :global,

        # what method should be used to stop the service?
        # :global - Stop the running service by disabling it
        # :local  - Stop the locally running service by banning it on this node
        # Note: by default restart does not stop services
        # if they are not running locally on the node
        :stop_mode_multistate => :local,
        :stop_mode_clone => :local,
        :stop_mode_simple => :global,

        # what service is considered running?
        # :global - The service is running on any node
        # :local  - The service is running on the local node
        :status_mode_multistate => :local,
        :status_mode_clone => :local,
        :status_mode_simple => :local,

        # try to stop and disable the basic init/upstart service
        # because it will mess with OCF-based Pacemaker primitives
        :disable_basic_service => true,
        # don't try to stop basic service for these primitive classes
        # because they are based on the native service manager
        :native_based_primitive_classes => %w(lsb systemd upstart),

        # add location constraint to allow the service to run on the current node
        # useful for asymmetric cluster mode
        :add_location_constraint => true,

        # restart the service only if it's running on this node
        # and skip restart if it's running elsewhere
        :restart_only_if_local => true,

        # cleanup the primitive before the status action.
        :cleanup_on_status => false,
        # cleanup the primitive before the start action
        :cleanup_on_start => true,
        # cleanup the primitive before the stop action
        :cleanup_on_stop => true,
        # cleanup primitive only if it has failures
        :cleanup_only_if_failures => true,
    }
  end

  # CIB and its sections
  ######################

  # create a new REXML CIB document
  # can read stub file for testing if @cib_file is defined
  # @return [REXML::Document] at '/'
  def cib
    return File.read @cib_file if @cib_file
    return @cib if @cib
    @cib = REXML::Document.new(raw_cib)
  end

  # reset all saved variables to obtain new data
  def cib_reset
    @raw_cib = nil
    @cib_file = nil
    @cib = nil
    @primitives = nil
    @primitives_structure = nil
    @locations_structure = nil
    @colocations_structure = nil
    @orders_structure = nil
    @nodes_structure = nil
  end

  # get lrm_rsc_ops section from lrm_resource section CIB section
  # @param lrm_resource [REXML::Element]
  # at /cib/status/node_state/lrm[@id="node-name"]/lrm_resources/lrm_resource[@id="resource-name"]/lrm_rsc_op
  # @return [REXML::Element]
  def cib_section_lrm_rsc_ops(lrm_resource)
    return unless lrm_resource.is_a? REXML::Element
    REXML::XPath.match lrm_resource, 'lrm_rsc_op'
  end

  # get node_state CIB section
  # @return [REXML::Element] at /cib/status/node_state
  def cib_section_nodes_state
    REXML::XPath.match cib, '//node_state'
  end

  # get all 'primitive' sections from CIB
  # @return [Array<REXML::Element>] at /cib/configuration/resources/primitive
  def cib_section_primitives
    REXML::XPath.match cib, '//primitive'
  end

  # get lrm_rsc_ops section from lrm_resource section CIB section
  # @param lrm [REXML::Element]
  # at /cib/status/node_state/lrm[@id="node-name"]/lrm_resources/lrm_resource
  # @return [REXML::Element]
  def cib_section_lrm_resources(lrm)
    return unless lrm.is_a? REXML::Element
    REXML::XPath.match lrm, 'lrm_resources/lrm_resource'
  end

  # get all 'rsc_location', 'rsc_order' and 'rsc_colocation' sections from CIB
  # @return [Array<REXML::Element>] at /cib/configuration/constraints/*
  def cib_section_constraints
    REXML::XPath.match cib, '//constraints/*'
  end

  # get all rule elements from the constraint element
  # @return [Array<REXML::Element>] at /cib/configuration/constraints/*/rule
  def cib_section_constraint_rules(constraint)
    return unless constraint.is_a? REXML::Element
    REXML::XPath.match constraint, 'rule'
  end

  # get cluster property CIB section
  # @return [REXML::Element]
  def cib_section_cluster_property
    REXML::XPath.match(cib, '/cib/configuration/crm_config/cluster_property_set').first
  end

  # get resource defaults CIB section
  # @return [REXML::Element]
  def cib_section_resource_defaults
    REXML::XPath.match(cib, '/cib/configuration/rsc_defaults/meta_attributes').first
  end

  # get operation defaults CIB section
  # @return [REXML::Element]
  def cib_section_operation_defaults
    REXML::XPath.match(cib, '/cib/configuration/op_defaults/meta_attributes').first
  end

  # Helpers
  #########

  # convert elements's attributes to hash
  # @param element [REXML::Element]
  # @return [Hash<String => String>]
  def attributes_to_hash(element)
    hash = {}
    element.attributes.each do |a, v|
      hash.store a.to_s, v.to_s
    end
    hash
  end

  # convert element's children to hash
  # of their attributes using key and hash key
  # @param element [REXML::Element]
  # @param key <String> use this attribute as hash key
  # @param tag <String> get only this type of children
  # @return [Hash<String => String>]
  def children_elements_to_hash(element, key, tag = nil)
    return unless element.is_a? REXML::Element
    elements = {}
    children = element.get_elements tag
    return elements unless children
    children.each do |child|
      child_structure = attributes_to_hash child
      name = child_structure[key]
      next unless name
      elements.store name, child_structure
    end
    elements
  end

  # convert element's children to array of their attributes
  # @param element [REXML::Element]
  # @param tag [String] get only this type of children
  # @return [Array<Hash>]
  def children_elements_to_array(element, tag = nil)
    return unless element.is_a? REXML::Element
    elements = []
    children = element.get_elements tag
    return elements unless children
    children.each do |child|
      child_structure = attributes_to_hash child
      next unless child_structure['id']
      elements << child_structure
    end
    elements
  end

  # copy value from one hash_like structure to another
  # if the value is present
  # @param from[Hash]
  # @param from_key [String,Symbol]
  # @param to [Hash]
  # @param to_key [String,Symbol,NilClass]
  def copy_value(from, from_key, to, to_key = nil)
    value = from[from_key]
    return value unless value
    to_key = from_key unless to_key
    to[to_key] = value
    value
  end

  def sort_data(data, key = 'id')
    data = data.values if data.is_a? Hash
    data.sort do |x, y|
      break 0 unless x[key] and y[key]
      x[key] <=> y[key]
    end
  end

  # Status calculations
  #####################

  # determine the status of a single operation
  # @param op [Hash<String => String>]
  # @return ['start','stop','master',nil]
  def operation_status(op)
    # skip incomplete ops
    return unless op['op-status'] == '0'

    if op['operation'] == 'monitor'
      # for monitor operation status is determined by its rc-code
      # 0 - start, 8 - master, 7 - stop, else - error
      case op['rc-code']
        when '0'
          'start'
        when '7'
          'stop'
        when '8'
          'master'
        else
          # not entirely correct but count failed monitor as 'stop'
          'stop'
      end
    elsif %w(start stop promote).include? op['operation']
      # for start/stop/promote status is set if op was successful
      # use master instead of promote
      return unless %w(0 7 8).include? op['rc-code']
      if op['operation'] == 'promote'
        'master'
      else
        op['operation']
      end
    else
      # other operations are irrelevant
      nil
    end
  end

  # determine resource status by parsing last operations
  # @param ops [Array<Hash>]
  # @return ['start','stop','master',nil]
  # nil means that status is unknown
  def determine_primitive_status(ops)
    status = nil
    ops.each do |op|
      op_status = operation_status op
      status = op_status if op_status
    end
    status
  end

  # decode lrm_resources section of CIB
  # @param lrm_resources [REXML::Element]
  # @return [Hash<String => Hash>]
  def decode_lrm_resources(lrm_resources)
    resources = {}
    lrm_resources.each do |lrm_resource|
      resource = attributes_to_hash lrm_resource
      id = resource['id']
      next unless id
      lrm_rsc_ops = cib_section_lrm_rsc_ops lrm_resource
      next unless lrm_rsc_ops
      ops = decode_lrm_rsc_ops lrm_rsc_ops
      resource.store 'ops', ops
      resource.store 'status', determine_primitive_status(ops)
      resource.store 'failed', failed_operations_found?(ops)
      resources.store id, resource
    end
    resources
  end

  # decode lrm_rsc_ops section of the resource's CIB
  # @param lrm_rsc_ops [REXML::Element]
  # @return [Array<Hash>]
  def decode_lrm_rsc_ops(lrm_rsc_ops)
    ops = []
    lrm_rsc_ops.each do |lrm_rsc_op|
      op = attributes_to_hash lrm_rsc_op
      next unless op['call-id']
      ops << op
    end
    ops.sort { |a, b| a['call-id'].to_i <=> b['call-id'].to_i }
  end

  # get nodes structure with resources and their statuses
  # @return [Hash<String => Hash>]
  def nodes
    return @nodes_structure if @nodes_structure
    @nodes_structure = {}
    cib_section_nodes_state.each do |node_state|
      node = attributes_to_hash node_state
      id = node['id']
      next unless id
      lrm = node_state.elements['lrm']
      next unless lrm
      lrm_resources = cib_section_lrm_resources lrm
      next unless lrm_resources
      resources = decode_lrm_resources lrm_resources
      node.store 'primitives', resources
      @nodes_structure.store id, node
    end
    @nodes_structure
  end

  # check if operations have same failed operations
  # that should be cleaned up later
  # @param ops [Array<Hash>]
  # @return [TrueClass,FalseClass]
  def failed_operations_found?(ops)
    ops.each do |op|
      # skip incompleate ops
      next unless op['op-status'] == '0'
      # skip useless ops
      next unless %w(start stop monitor promote).include? op['operation']

      # are there failed start, stop
      if %w(start stop promote).include? op['operation']
        return true if op['rc-code'] != '0'
      end

      # are there failed monitors
      if op['operation'] == 'monitor'
        return true unless %w(0 7 8).include? op['rc-code']
      end
    end
    false
  end

  # get a status of a primitive on the entire cluster
  # of on a node if node name param given
  # @param primitive [String]
  # @param node [String]
  # @return [String]
  def primitive_status(primitive, node = nil)
    if node
      nodes.
          fetch(node, {}).
          fetch('primitives', {}).
          fetch(primitive, {}).
          fetch('status', nil)
    else
      statuses = []
      nodes.each do |k, v|
        status = v.fetch('primitives', {}).
            fetch(primitive, {}).
            fetch('status', nil)
        statuses << status
      end
      status_values = {
          'stop' => 0,
          'start' => 1,
          'master' => 2,
      }
      statuses.max_by do |status|
        return unless status
        status_values[status]
      end
    end
  end

  # does this primitive have failed operations?
  # @param primitive [String] primitive name
  # @param node [String] on this node if given
  # @return [TrueClass,FalseClass]
  def primitive_has_failures?(primitive, node = nil)
    return unless primitive_exists? primitive
    if node
      nodes.
          fetch(node, {}).
          fetch('primitives', {}).
          fetch(primitive, {}).
          fetch('failed', nil)
    else
      nodes.each do |k, v|
        failed = v.fetch('primitives', {}).
            fetch(primitive, {}).
            fetch('failed', nil)
        return true if failed
      end
      false
    end
  end

  # determine if a primitive is running on the entire cluster
  # of on a node if node name param given
  # @param primitive [String] primitive id
  # @param node [String] on this node if given
  # @return [TrueClass,FalseClass]
  def primitive_is_running?(primitive, node = nil)
    return unless primitive_exists? primitive
    status = primitive_status primitive, node
    return status unless status
    %w(start master).include? status
  end

  # check if primitive is running as a master
  # either anywhere or on the give node
  # @param primitive [String] primitive id
  # @param node [String] on this node if given
  # @return [TrueClass,FalseClass]
  def primitive_has_master_running?(primitive, node = nil)
    is_multistate = primitive_is_multistate? primitive
    return is_multistate unless is_multistate
    status = primitive_status primitive, node
    return status unless status
    status == 'master'
  end

  # Primitive configuration parser
  ################################

  # get primitives configuration structure with primitives and their attributes
  # @return [Hash<String => Hash>]
  def primitives
    return @primitives_structure if @primitives_structure
    @primitives_structure = {}
    cib_section_primitives.each do |primitive|
      primitive_structure = {}
      id = primitive.attributes['id']
      next unless id
      primitive_structure.store 'name', id
      primitive.attributes.each do |k, v|
        primitive_structure.store k.to_s, v
      end

      if primitive.parent.name and primitive.parent.attributes['id']
        complex_structure = {
            'id' => primitive.parent.attributes['id'],
            'type' => primitive.parent.name
        }

        complex_meta_attributes = primitive.parent.elements['meta_attributes']
        if complex_meta_attributes
          complex_meta_attributes_structure = children_elements_to_hash complex_meta_attributes, 'name', 'nvpair'
          complex_structure.store 'meta_attributes', complex_meta_attributes_structure
        end

        primitive_structure.store 'name', complex_structure['id']
        primitive_structure.store 'complex', complex_structure
      end

      instance_attributes = primitive.elements['instance_attributes']
      if instance_attributes
        instance_attributes_structure = children_elements_to_hash instance_attributes, 'name', 'nvpair'
        primitive_structure.store 'instance_attributes', instance_attributes_structure
      end

      meta_attributes = primitive.elements['meta_attributes']
      if meta_attributes
        meta_attributes_structure = children_elements_to_hash meta_attributes, 'name', 'nvpair'
        primitive_structure.store 'meta_attributes', meta_attributes_structure
      end

      operations = primitive.elements['operations']
      if operations
        operations_structure = children_elements_to_hash operations, 'id', 'op'
        primitive_structure.store 'operations', operations_structure
      end

      @primitives_structure.store id, primitive_structure
    end
    @primitives_structure
  end

  # check if primitive exists in the confiuguration
  # @param primitive primitive id or name
  def primitive_exists?(primitive)
    primitives.key? primitive
  end

  # return primitive class
  # @param primitive [String] primitive id
  # @return [String] primitive class
  def primitive_class(primitive)
    return unless primitive_exists? primitive
    primitives[primitive]['class']
  end

  # return primitive type
  # @param primitive [String] primitive id
  # @return [String] primitive type
  def primitive_type(primitive)
    return unless primitive_exists? primitive
    primitives[primitive]['type']
  end

  # check if primitive is clone or multistate
  # @param primitive [String] primitive id
  # @return [TrueClass,FalseClass]
  def primitive_is_complex?(primitive)
    return unless primitive_exists? primitive
    primitives[primitive].key? 'complex'
  end

  # check if primitive is clone
  # @param primitive [String] primitive id
  # @return [TrueClass,FalseClass]
  def primitive_is_clone?(primitive)
    is_complex = primitive_is_complex? primitive
    return is_complex unless is_complex
    primitives[primitive]['complex']['type'] == 'clone'
  end

  # check if primitive is multistate
  # @param primitive [String] primitive id
  # @return [TrueClass,FalseClass]
  def primitive_is_multistate?(primitive)
    is_complex = primitive_is_complex? primitive
    return is_complex unless is_complex
    primitives[primitive]['complex']['type'] == 'master'
  end

  # determine if primitive is managed
  # @param primitive [String] primitive id
  # @return [TrueClass,FalseClass]
  def primitive_is_managed?(primitive)
    return unless primitive_exists? primitive
    is_managed = primitives.fetch(primitive).fetch('meta_attributes', {}).fetch('is-managed', {}).fetch('value', 'true')
    is_managed == 'true'
  end

  # determine if primitive has target-state started
  # @param primitive [String] primitive id
  # @return [TrueClass,FalseClass]
  def primitive_is_started?(primitive)
    return unless primitive_exists? primitive
    target_role = primitives.fetch(primitive).fetch('meta_attributes', {}).fetch('target-role', {}).fetch('value', 'Started')
    target_role == 'Started'
  end

  # get the name of the DC node
  # @return [String, nil]
  def dc
    cib_element = cib.elements['/cib']
    return unless cib_element
    dc_node = cib_element.attribute('dc-uuid')
    return unless dc_node
    return if dc_node == 'NONE'
    dc_node.to_s
  end

  # Basic actions
  ###############

  # get the raw CIB from Pacemaker
  # @return [String] cib xml
  def raw_cib
    @raw_cib = cibadmin '-Q'
    if !@raw_cib or @raw_cib == ''
      fail 'Could not dump CIB XML!'
    end
    @raw_cib
  end

  # check if pacemaker is online and we can work with it
  # pacemaker is online if cib can be downloaded
  # and DC have been designated
  # @return [TrueClass,FalseClass]
  def is_online?
    begin
      Timeout::timeout(pacemaker_options[:retry_timeout]) do
        dc_version = crm_attribute '-q', '--type', 'crm_config', '--query', '--name', 'dc-version'
        return false unless dc_version
        return false if dc_version.empty?
        return false unless dc
        return false unless cib_section_nodes_state
        true
      end
    rescue Puppet::ExecutionFailure => e
      debug "Offline: #{e.message}"
      false
    rescue Timeout::Error
      debug 'Online check timeout!'
      false
    end
  end

  # sets the meta attribute of a primitive
  # @param primitive [String] primitive's id
  # @param attribute [String] atttibute's name
  # @param value [String] attribute's value
  def set_primitive_meta_attribute(primitive, attribute, value)
    options = ['--quiet', '--resource', primitive]
    options += ['--set-parameter', attribute, '--meta', '--parameter-value', value]
    retry_block { crm_resource options }
  end

  # disable this primitive
  # @param primitive [String] what primitive to disable
  def disable_primitive(primitive)
    set_primitive_meta_attribute primitive, 'target-role', 'Stopped'
  end

  alias :stop_primitive :disable_primitive

  # enable this primitive
  # @param primitive [String] what primitive to enable
  def enable_primitive(primitive)
    set_primitive_meta_attribute primitive, 'target-role', 'Started'
  end

  alias :start_primitive :enable_primitive

  # manage this primitive
  # @param primitive [String] what primitive to manage
  def manage_primitive(primitive)
    set_primitive_meta_attribute primitive, 'is-managed', 'true'
  end

  # unamanage this primitive
  # @param primitive [String] what primitive to unmanage
  def unmanage_primitive(primitive)
    set_primitive_meta_attribute primitive, 'is-managed', 'false'
  end

  # ban this primitive
  # @param primitive [String] what primitive to ban
  # @param node [String] on which node this primitive should be banned
  def ban_primitive(primitive, node)
    options = ['--quiet', '--resource', primitive, '--node', node]
    options += ['--ban']
    retry_block { crm_resource options }
  end

  # unban this primitive
  # @param primitive [String] what primitive to unban
  # @param node [String] on which node this primitive should be unbanned
  def unban_primitive(primitive, node)
    options = ['--quiet', '--resource', primitive, '--node', node]
    options += ['--clear']
    retry_block { crm_resource options }
  end

  alias :clear_primitive :unban_primitive

  # move this primitive
  # @param primitive [String] what primitive to un-move
  # @param node [String] to which node the primitive should be moved
  def move_primitive(primitive, node)
    options = ['--quiet', '--resource', primitive, '--node', node]
    options += ['--move']
    retry_block { crm_resource options }
  end

  # un-move this primitive
  # @param primitive [String] what primitive to un-move
  # @param node [String] from which node the primitive should be un-moved
  def unmove_primitive(primitive, node)
    options = ['--quiet', '--resource', primitive, '--node', node]
    options += ['--un-move']
    retry_block { crm_resource options }
  end

  # cleanup this primitive
  # @param primitive [String] what primitive to cleanup
  # @param node [String] on which node to cleanup (optional)
  # cleanups on every node if node is not given
  def cleanup_primitive(primitive, node = nil)
    options = ['--quiet', '--resource', primitive]
    options += ['--node', node] if node
    options += ['--cleanup']
    retry_block { crm_resource options }
  end

  # apply the XML patch to CIB
  # @param xml [String, REXML::Element] the patch to apply
  def cibadmin_apply_patch(xml)
    xml = xml_pretty_format xml if xml.is_a? REXML::Element
    retry_block { cibadmin '--force', '--patch', '--sync-call', '--xml-text', xml.to_s }
  end

  # ask cibadmin to remove the first element matchig the input
  # @param xml [String, REXML::Element]
  def cibadmin_remove(xml)
    xml = xml_pretty_format xml if xml.is_a? REXML::Element
    retry_block { cibadmin '--force', '--delete', '--sync-call', '--xml-text', xml.to_s }
  end

  # Constraints actions
  #####################

  # parse constraint rule elements to the rule structure
  # @param element [REXML::Element]
  # @return [Hash<String => Hash>]
  def decode_constraint_rules(element)
    rules = cib_section_constraint_rules element
    return [] unless rules.any?
    rules_array = []
    rules.each do |rule|
      rule_structure = attributes_to_hash rule
      next unless rule_structure['id']
      rule_expressions = children_elements_to_array rule, 'expression'
      rule_structure.store 'expressions', rule_expressions if rule_expressions
      rules_array << rule_structure
    end
    rules_array.sort_by { |rule| rule['id'] }
  end

  # decode a single constraint element to the data structure
  # @param element [REXML::Element]
  # @return [Hash<String => String>]
  def decode_constraint(element)
    return unless element.is_a? REXML::Element
    return unless element.attributes['id']
    return unless element.name

    constraint_structure = attributes_to_hash element
    constraint_structure.store 'type', element.name

    rules = decode_constraint_rules element
    constraint_structure.store 'rules', rules if rules.any?
    constraint_structure
  end

  # location constraints found in the CIB
  # filter them by the provided tag name
  # @param type [String] filter this location type
  # @return [Hash<String => Hash>]
  def constraints(type = nil)
    locations = {}
    cib_section_constraints.each do |constraint|
      constraint_structure = decode_constraint constraint
      next unless constraint_structure
      next unless constraint_structure['id']
      next unless constraint_structure['type'] == type if type
      constraint_structure.delete 'type'
      locations.store constraint_structure['id'], constraint_structure
    end
    locations
  end

  # get location constraints and use mnemoisation on the list
  # @return [Hash<String => Hash>]
  def constraint_locations
    return @locations_structure if @locations_structure
    @locations_structure = constraints 'rsc_location'
  end

  # get colocation constraints and use mnemoisation on the list
  # @return [Hash<String => Hash>]
  def constraint_colocations
    return @colocations_structure if @colocations_structure
    @colocations_structure = constraints 'rsc_colocation'
  end

  # get order constraints and use mnemoisation on the list
  # @return [Hash<String => Hash>]
  def constraint_orders
    return @orders_structure if @orders_structure
    @orders_structure = constraints 'rsc_order'
  end

  # construct the constraint unique name
  # from primitive's and node's names
  # @param primitive [String]
  # @param node [String]
  # @return [String]
  def service_location_name(primitive, node)
    "#{primitive}-on-#{node}"
  end

  # add a location constraint to enable a service on a node
  # @param primitive [String] the primitive's name
  # @param node [String] the node's name
  # @param score [Numeric,String] score value
  def service_location_add(primitive, node, score = 100)
    location_structure = {
        'id' => service_location_name(primitive, node),
        'node' => node,
        'rsc' => primitive,
        'score' => score,
    }
    constraint_location_add location_structure
  end

  # check if service location exists for this primitive on this node
  # @param primitive [String] the primitive's name
  # @param node [String] the node's name
  # @return [:true,:false]
  def service_location_exists?(primitive, node)
    id = service_location_name primitive, node
    constraint_location_exists? id
  end

  # add a location constraint
  # @param location_structure [Hash<String => String>] the location data structure
  def constraint_location_add(location_structure)
    location_structure['__crm_diff_marker__'] = 'added:top'
    location_patch = xml_document %w(diff diff-added cib configuration constraints)
    location_element = xml_rsc_location location_structure
    fail "Could not create XML patch from location '#{location_structure.inspect}'!" unless location_element
    location_patch.add_element location_element
    cibadmin_apply_patch xml_pretty_format location_patch.root
  end

  # remove a location constraint
  # @param id [String] the constraint id
  def constraint_location_remove(id)
    cibadmin_remove "<rsc_location id='#{id}'/>"
  end

  # check if locations constraint exists
  # @param id [String] the constraint id
  # @return [TrueClass,FalseClass]
  def constraint_location_exists?(id)
    constraint_locations.key? id
  end

  # Puppet translators
  ####################

  # return service status value expected by Puppet
  # puppet wants :running or :stopped symbol
  # @param primitive [String] primitive id
  # @param node [String] on this node if given
  # @return [:running,:stopped]
  def get_primitive_puppet_status(primitive, node = nil)
    if primitive_is_running? primitive, node
      :running
    else
      :stopped
    end
  end

  # return service enabled status value expected by Puppet
  # puppet wants :true or :false symbols
  # @param primitive [String]
  # @return [:true,:false]
  def get_primitive_puppet_enable(primitive)
    if primitive_is_managed? primitive
      :true
    else
      :false
    end
  end

  # Wait actions
  ##############

  # retry the given command until it runs without errors
  # or for RETRY_COUNT times with RETRY_STEP sec step
  # print cluster status report on fail
  # @param options [Hash]
  def retry_block(options = {})
    options = pacemaker_options.merge options

    options[:retry_count].times do
      begin
        out = Timeout::timeout(options[:retry_timeout]) { yield }
        if options[:retry_false_is_failure]
          return out if out
        else
          return out
        end
      rescue => e
        Puppet.debug "Execution failure: #{e.message}"
      end
      sleep options[:retry_step]
    end
    fail "Execution timeout after #{options[:retry_count] * options[:retry_step]} seconds!" if options[:retry_fail_on_timeout]
  end

  # wait for pacemaker to become online
  def wait_for_online
    debug "Waiting #{pacemaker_options[:retry_count] * pacemaker_options[:retry_step]} seconds for Pacemaker to become online"
    retry_block { is_online? }
    debug 'Pacemaker is online'
  end

  # cleanup a primitive and then wait until
  # we can get it's status again because
  # cleanup blocks operations sections for a while
  # @param primitive [String] primitive name
  def cleanup_with_wait(primitive, node = nil)
    message = "Cleanup primitive '#{primitive}' and wait until cleanup finishes"
    message += " on node '#{node}'" if node
    debug message
    cleanup_primitive(primitive, node)
    retry_block do
      cib_reset
      primitive_status(primitive) != nil
    end
    message = "Primitive '#{primitive}' have been cleaned up and is online again"
    message += " on node '#{node}'" if node
    debug message
  end

  # wait for primitive to start
  # if node is given then start on this node
  # @param primitive [String] primitive id
  # @param node [String] on this node if given
  def wait_for_start(primitive, node = nil)
    message = "Waiting #{pacemaker_options[:retry_count] * pacemaker_options[:retry_step]} seconds for service '#{primitive}' to start"
    message += " on node '#{node}'" if node
    debug message
    retry_block do
      cib_reset
      primitive_is_running? primitive, node
    end
    message = "Service '#{primitive}' have started"
    message += " on node '#{node}'" if node
    debug message
  end

  # wait for primitive to start as a master
  # if node is given then start as a master on this node
  # @param primitive [String] primitive id
  # @param node [String] on this node if given
  def wait_for_master(primitive, node = nil)
    message = "Waiting #{pacemaker_options[:retry_count] * pacemaker_options[:retry_step]} seconds for service '#{primitive}' to start master"
    message += " on node '#{node}'" if node
    debug message
    retry_block do
      cib_reset
      primitive_has_master_running? primitive, node
    end
    message = "Service '#{primitive}' have started master"
    message += " on node '#{node}'" if node
    debug message
  end

  # wait for primitive to stop
  # if node is given then start on this node
  # @param primitive [String] primitive id
  # @param node [String] on this node if given
  def wait_for_stop(primitive, node = nil)
    message = "Waiting #{pacemaker_options[:retry_count] * pacemaker_options[:retry_step]} seconds for service '#{primitive}' to stop"
    message += " on node '#{node}'" if node
    debug message
    retry_block do
      cib_reset
      result = primitive_is_running? primitive, node
      result.is_a? FalseClass
    end
    message = "Service '#{primitive}' was stopped"
    message += " on node '#{node}'" if node
    debug message
  end

  # Reports
  #########

  # generate report of primitive statuses by node
  # mostly for debugging
  # @return [Hash]
  def primitives_status_by_node
    report = {}
    return unless nodes.is_a? Hash
    nodes.each do |node_name, node_data|
      primitives_of_node = node_data['primitives']
      next unless primitives_of_node.is_a? Hash
      primitives_of_node.each do |primitive, primitive_data|
        primitive_status = primitive_data['status']
        report[primitive] = {} unless report[primitive].is_a? Hash
        report[primitive][node_name] = primitive_status
      end
    end
    report
  end

  # form a cluster status report for debugging
  # @return [String]
  def cluster_debug_report(tag = nil)
    report = "\n"
    report += 'Pacemaker debug block start'
    report += " at '#{tag}'" if tag
    report += "\n"
    primitives_status_by_node.each do |primitive, data|
      primitive_name = primitive
      primitive_name = primitives[primitive]['name'] if primitives[primitive]['name']
      primitive_type = 'Simple'
      primitive_type = 'Cloned' if primitive_is_clone? primitive
      primitive_type = 'Multistate' if primitive_is_multistate? primitive

      report += "-> #{primitive_type} primitive: '#{primitive_name}'"
      report += ' (M)' unless primitive_is_managed? primitive
      report += "\n"
      nodes = []
      data.keys.sort.each do |node_name|
        node_status = data.fetch(node_name).upcase
        node_block = "#{node_name}: #{node_status}"
        node_block += ' (F)' if primitive_has_failures? primitive, node_name
        node_block += ' (L)' if constraint_location_exists? primitive, node_name
        nodes << node_block
      end
      report += '   ' + nodes.join(' | ') + "\n"
    end
    pacemaker_options[:debug_show_properties].each do |p|
      report += "* #{p}: #{cluster_property_value p}\n" if cluster_property_defined? p
    end
    report += 'Pacemaker debug block end'
    report += " at '#{tag}'" if tag
    report + "\n"
  end

  # Cluster properties
  ####################

  # get cluster property structure
  # @return [Hash<String => Hash>]
  def cluster_properties
    return @cluster_properties_structure if @cluster_properties_structure
    @cluster_properties_structure = children_elements_to_hash cib_section_cluster_property, 'name'
  end

  # get the value of a cluster property by it's name
  # @param property_name [String] the name of the property
  # @return [String]
  def cluster_property_value(property_name)
    return unless cluster_property_defined? property_name
    cluster_properties[property_name]['value']
  end

  # set the value to this cluster's property
  # @param property_name [String] the name of the property
  # @param property_value [String] the value of the property
  def cluster_property_set(property_name, property_value)
    options = ['--quiet', '--type', 'crm_config', '--name', property_name]
    options += ['--update', property_value]
    retry_block { crm_attribute options }
  end

  # delete this cluster's property
  # @param property_name [String] the name of the property
  def cluster_property_delete(property_name)
    options = ['--quiet', '--type', 'crm_config', '--name', property_name]
    options += ['--delete']
    retry_block { crm_attribute options }
  end

  # check if this property has a value
  # @param property_name [String] the name of the property
  # @return [TrueClass,FalseClass]
  def cluster_property_defined?(property_name)
    return false unless cluster_properties.key? property_name
    return false unless cluster_properties[property_name].is_a? Hash and cluster_properties[property_name]['value']
    true
  end

  # Resource defaults
  ###################

  def resource_defaults
    return @resource_defaults_structure if @resource_defaults_structure
    @resource_defaults_structure = children_elements_to_hash cib_section_resource_defaults, 'name'
  end

  def resource_default_value(attribute_name)
    return unless resource_default_defined? attribute_name
    resource_defaults[attribute_name]['value']
  end

  # crm_attribute --type rsc_defaults --attr-name is-managed --attr-value false
  def resource_default_set(attribute_name, attribute_value)
    options = ['--quiet', '--type', 'rsc_defaults', '--attr-name', attribute_name]
    options += ['--attr-value', attribute_value]
    retry_block { crm_attribute options }
  end

  def resource_default_delete(attribute_name)
    options = ['--quiet', '--type', 'rsc_defaults', '--attr-name', attribute_name]
    options += ['--delete-attr']
    retry_block { crm_attribute options }
  end

  def resource_default_defined?(attribute_name)
    return false unless resource_defaults.key? attribute_name
    return false unless resource_defaults[attribute_name].is_a? Hash and resource_defaults[attribute_name]['value']
    true
  end

  # XML generation
  ################

  # create a new xml document
  # @param path [String,Array<String>] create this sequence of path elements
  # @param root [REXML::Document] use existing element as a root instead of creating a new one
  # @return [REXML::Element] element point to the last path component
  # use .root to get the document root
  def xml_document(path, root = nil)
    root = REXML::Document.new unless root
    element = root
    path = Array(path) unless path.is_a? Array
    path.each do |component|
      element = element.add_element component
    end
    element
  end

  # convert hash to xml element
  # @param tag [String] what xml tag to create
  # @param hash [Hash] attributes data structure
  # @param skip_attributes [String,Array<String>] skip these hash keys
  # @return [REXML::Element]
  def xml_element(tag, hash, skip_attributes = nil)
    return unless hash.is_a? Hash
    element = REXML::Element.new tag
    hash.each do |attribute, value|
      attribute = attribute.to_s
      # skip attributes that were specified to be skipped
      next if skip_attributes == attribute or
          (skip_attributes.respond_to? :include? and skip_attributes.include? attribute)
      # skip array and hash values. add only scalar ones
      next if value.is_a? Array or value.is_a? Hash
      element.add_attribute attribute, value
    end
    element
  end

  def xml_primitive(data)
    return unless data and data.is_a? Hash
    primitive_skip_attributes = %w(name parent instance_attributes operations meta_attributes utilization)
    primitive_element = xml_element 'primitive', data, primitive_skip_attributes

    # instance attributes
    if data['instance_attributes'].respond_to? :each and data['instance_attributes'].any?
      instance_attributes_document = xml_document 'instance_attributes', primitive_element
      instance_attributes_document.add_attribute 'id', data['id'] + '-instance_attributes'
      sort_data(data['instance_attributes']).each do |instance_attribute|
        instance_attribute_element = xml_element 'nvpair', instance_attribute
        instance_attributes_document.add_element instance_attribute_element if instance_attribute_element
      end
    end

    # meta attributes
    if data['meta_attributes'].respond_to? :each and data['meta_attributes'].any?
      complex_meta_attributes_document = xml_document 'meta_attributes', primitive_element
      complex_meta_attributes_document.add_attribute 'id', data['id'] + '-meta_attributes'
      sort_data(data['meta_attributes']).each do |meta_attribute|
        meta_attribute_element = xml_element 'nvpair', meta_attribute
        complex_meta_attributes_document.add_element meta_attribute_element if meta_attribute_element
      end
    end

    # operations
    if data['operations'].respond_to? :each and data['operations'].any?
      operations_document = xml_document 'operations', primitive_element
      sort_data(data['operations']).each do |operation|
        operation_element = xml_element 'op', operation
        operations_document.add_element operation_element if operation_element
      end
    end

    # complex structure
    if data['complex'].is_a? Hash and data['complex']['type']
      skip_complex_attributes = 'type'
      supported_complex_types = %w(clone master meta_attributes)
      complex_tag_name = data['complex']['type']
      return unless supported_complex_types.include? complex_tag_name
      complex_element = xml_element complex_tag_name, data['complex'], skip_complex_attributes

      # complex meta attributes
      if data['complex']['meta_attributes'].respond_to? :each and data['complex']['meta_attributes'].any?
        complex_meta_attributes_document = xml_document 'meta_attributes', complex_element
        complex_meta_attributes_document.add_attribute 'id', data['complex']['id'] + '-meta_attributes'
        sort_data(data['complex']['meta_attributes']).each do |meta_attribute|
          complex_meta_attribute_element = xml_element 'nvpair', meta_attribute
          complex_meta_attributes_document.add_element complex_meta_attribute_element if complex_meta_attribute_element
        end
      end

      complex_element.add_element primitive_element
      return complex_element
    end

    primitive_element
  end

  # generate rsc_location elements from data structure
  # @param data [Hash]
  # @return [REXML::Element]
  def xml_rsc_location(data)
    return unless data and data.is_a? Hash
    # create an element from the top level hash and skip 'rules' attribute
    # because if should be processed as children elements and useless 'type' attribute
    rsc_location_element = xml_element 'rsc_location', data, %w(rules type)

    # there are no rule elements
    return rsc_location_element unless data['rules'] and data['rules'].respond_to? :each

    # create a rule element with attributes and treat expressions as children elements
    sort_data(data['rules']).each do |rule|
      next unless rule.is_a? Hash
      rule_element = xml_element 'rule', rule, 'expressions'
      # add expression children elements to the rule element if the are present
      if rule['expressions'] and rule['expressions'].respond_to? :each
        sort_data(rule['expressions']).each do |expression|
          next unless expression.is_a? Hash
          expression_element = xml_element 'expression', expression
          rule_element.add_element expression_element
        end
      end
      rsc_location_element.add_element rule_element
    end
    rsc_location_element
  end

  # generate rsc_colocation elements from data structure
  # @param data [Hash]
  # @return [REXML::Element]
  def xml_rsc_colocation(data)
    return unless data and data.is_a? Hash
    xml_element 'rsc_colocation', data, 'type'
  end

  # generate rsc_order elements from data structure
  # @param data [Hash]
  # @return [REXML::Element]
  def xml_rsc_order(data)
    return unless data and data.is_a? Hash
    xml_element 'rsc_order', data, 'type'
  end

  # output xml element as the actual xml text with indentation
  # @param element [REXML::Element]
  # @return [String]
  def xml_pretty_format(element)
    return unless element.is_a? REXML::Element
    formatter = REXML::Formatters::Pretty.new
    formatter.compact = true
    xml=''
    formatter.write element, xml
    xml + "\n"
  end

end

# TODO: groups
# TODO: op_defaults
# TODO: split to subfiles
# TODO: resource <-> constraint autorequire/autobefore
# TODO: constraint fail is resource missing
# TODO: resource refuse to delete if constrains present or remove them too
# TODO: refactor status-metadata processing
# TODO: refactor options
# TODO: options and rules arrays sort? sets?
