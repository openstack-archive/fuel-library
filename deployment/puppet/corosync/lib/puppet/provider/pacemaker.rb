require 'rexml/document'

module Pacemaker

  @raw_cib = nil
  @cib = nil
  @primitives = nil
  @primitives_structure = nil

  attr_accessor :raw_cib_file

  RETRY_COUNT = 30
  RETRY_STEP = 3

  # get a raw CIB from cibadmin
  # or from a debug file if raw_cib_file is set
  # @return [String] cib xml
  def raw_cib
    # Puppet.debug 'Get a new CIB XML'
    return File.read raw_cib_file if raw_cib_file
    @raw_cib = cibadmin '-Q'
    if @raw_cib == '' or not @raw_cib
      raise 'Could not dump CIB XML!'
    end
    @raw_cib
  end

  # create a new REXML CIB document
  # @return [REXML::Document] at '/'
  def cib
    return @cib if @cib
    @cib = REXML::Document.new(raw_cib)
  end

  # reset all saved variables to obtain new data
  def cib_reset
    # Puppet.debug 'Reset CIB memoization'
    @raw_cib = nil
    @cib = nil
    @primitives = nil
    @primitives_structure = nil
    @nodes_structure = nil
  end

  # get status CIB section
  # @return [REXML::Element] at /cib/status
  def cib_section_status
    REXML::XPath.match cib, '/cib/status'
  end

  # get lrm_rsc_ops section from lrm_resource section CIB section
  # @param lrm_resource [REXML::Element]
  # at /cib/status/node_state/lrm[@id="node-name"]/lrm_resources/lrm_resource[@id="resource-name"]/lrm_rsc_op
  # @return [REXML::Element]
  def cib_section_lrm_rsc_ops(lrm_resource)
    REXML::XPath.match lrm_resource, 'lrm_rsc_op'
  end

  # get node_state CIB section
  # @return [REXML::Element] at /cib/status/node_state
  def cib_section_nodes_state
    REXML::XPath.match cib_section_status, 'node_state'
  end

  # get primitives CIB section
  # @return [REXML::Element] at /cib/configuration/resources/primitive
  def cib_section_primitives
    REXML::XPath.match cib, '//primitive'
  end

  # get lrm_rsc_ops section from lrm_resource section CIB section
  # @param lrm [REXML::Element]
  # at /cib/status/node_state/lrm[@id="node-name"]/lrm_resources/lrm_resource
  # @return [REXML::Element]
  def cib_section_lrm_resources(lrm)
    REXML::XPath.match lrm, 'lrm_resources/lrm_resource'
  end

  # determine resource status by parsing last operations
  # @param ops [Array<Hash>]
  # @return [String]
  def determine_primitive_status(ops)
    status = nil
    ops.each do |op|
      # skip incompleate ops
      next unless op['op-status'] == '0'
      # skip useless ops
      next unless %w(start stop monitor promote).include? op['operation']
      # skip failed non-monitor ops
      next unless op['operation'] == 'monitor' or op['rc-code'] == '0'

      if %w(start stop).include? op['operation']
        status = op['operation']
      elsif op['operation'] == 'promote'
        status = 'master'
      elsif %w(0 8).include? op['rc-code']
        status = 'start'
      else
        status = 'stop'
      end
    end
    status
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
  # @param key <String>
  # @return [Hash<String => String>]
  def elements_to_hash(element, key, tag = nil)
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
    ops.sort { |a,b| a['call-id'].to_i <=> b['call-id'].to_i }
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
      lrm_resources = cib_section_lrm_resources lrm
      resources = decode_lrm_resources lrm_resources
      node.store 'primitives', resources
      @nodes_structure.store id, node
    end
    @nodes_structure
  end

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
        parent_structure = {
            'id' => primitive.parent.attributes['id'],
            'type' => primitive.parent.name
        }
        primitive_structure.store 'name', parent_structure['id']
        primitive_structure.store 'parent', parent_structure
      end

      instance_attributes = primitive.elements['instance_attributes']
      if instance_attributes
        instance_attributes_structure = elements_to_hash instance_attributes, 'name', 'nvpair'
        primitive_structure.store 'instance_attributes', instance_attributes_structure
      end

      meta_attributes = primitive.elements['meta_attributes']
      if meta_attributes
        meta_attributes_structure = elements_to_hash meta_attributes, 'name', 'nvpair'
        primitive_structure.store 'meta_attributes', meta_attributes_structure
      end

      operations = primitive.elements['operations']
      if operations
        operations_structure = elements_to_hash operations, 'id', 'op'
        primitive_structure.store 'operations', operations_structure
      end

      @primitives_structure.store id, primitive_structure
    end
    @primitives_structure
  end

  # check if primitive is clone or multistate
  # @param primitive [String] primitive id
  # @return [TrueClass,FalseClass]
  def primitive_is_complex?(primitive)
    return nil unless primitives.key? primitive
    primitives[primitive].key? 'parent'
  end

  # stop this primitive
  # @param primitive [String]
  def stop_primitive(primitive)
    pcs 'resource', 'meta', primitive, 'target-role=Stopped'
  end

  # start this primitive
  # @param primitive [String]
  def start_primitive(primitive)
    pcs 'resource', 'meta', primitive, 'target-role=Started'
  end

  # ban this primitive
  # @param primitive [String]
  def ban_primitive(primitive)
    pcs 'resource', 'ban', primitive
  end

  # move this primitive
  # @param primitive [String]
  def move_primitive(primitive)
    pcs 'resource', 'move',  primitive
  end

  # unban/unmove this primitive
  # @param primitive [String]
  def unban_primitive(primitive)
    pcs 'resource', 'clear',  primitive
  end
  alias :clear_primitive :unban_primitive
  alias :unmove_primitive :unban_primitive

  # cleanup this primitive
  # @param primitive [String]
  def cleanup_primitive(primitive)
    pcs 'resource', 'cleanup', primitive
  end

  # manage this primitive
  # @param primitive [String]
  def manage_primitive(primitive)
    pcs 'resource', 'manage', primitive
  end

  # unamanage this primitive
  # @param primitive [String]
  def unmanage_primitive(primitive)
    pcs 'resource', 'unmanage', primitive
  end

  # set quorum_policy of the cluster
  # @param primitive [String]
  def no_quorum_policy(primitive)
    pcs 'property', 'set', "no-quorum-policy=#{primitive}"
  end

  # set maintenance_mode of the cluster
  # @param primitive [TrueClass,FalseClass]
  def maintenance_mode(primitive)
    pcs 'property', 'set', "maintenance-mode=#{primitive}"
  end

  # add a location constraint
  # @param primitive [String] the primitive's name
  # @param node [String] the node's name
  # @param score [Numeric,String] score value
  def constraint_location_add(primitive, node, score = 100)
    id = "#{primitive}_on_#{node}"
    pcs 'constraint', 'location', 'add', id, primitive, node, score
  end

  # remove a location constraint
  # @param primitive [String] the primitive's name
  # @param node [String] the node's name
  def constraint_location_remove(primitive, node)
    id = "#{primitive}_on_#{node}"
    pcs 'constraint', 'location', 'remove', id
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
          fetch('primitives',{}).
          fetch(primitive, {}).
          fetch('status', nil)
    else
      statuses = []
      nodes.each do |k,v|
        status = v.fetch('primitives',{}).
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
          fetch('primitives',{}).
          fetch(primitive, {}).
          fetch('failed', nil)
    else
      nodes.each do |k,v|
        failed = v.fetch('primitives',{}).
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
  def primitive_running?(primitive, node = nil)
    return unless primitive_exists? primitive
    status = primitive_status primitive, node
    return unless status
    %w(start master).include? status
  end

  # return service status value expected by Puppet
  # puppet wants 'running' or 'stopped' string
  # @param primitive [String] primitive id
  # @param node [String] on this node if given
  # @return ['running','stopped']
  def get_primitive_puppet_status(primitive, node = nil)
    if primitive_running? primitive, node
      'running'
    else
      'stopped'
    end
  end

  # return service enabled status value expected by Puppet
  # puppet wants 'true' or 'false' as a string
  # @param primitive [String]
  # @return ['true','false']
  def get_primitive_puppet_enable(primitive)
    primitive_is_managed?(primitive).to_s
  end

  # check if primitive exists in the confiuguration
  # @param primitive primitive id or name
  def primitive_exists?(primitive)
    primitives.key? primitive
  end

  # determine if primitive is managed
  # @param primitive [String] primitive id
  # @return [TrueClass,FalseClass]
  # TODO: will not work correctly if cluster is in management mode
  def primitive_is_managed?(primitive)
    return unless primitive_exists? primitive
    is_managed = primitives.fetch(primitive).fetch('meta_attributes', {}).fetch('is-managed', {}).fetch('value', 'true')
    is_managed == 'true'
  end

  # determine if primitive has target-state started
  # @param primitive [String] primitive id
  # @return [TrueClass,FalseClass]
  # TODO: will not work correctly if target state is set globally to stopped
  def primitive_is_started?(primitive)
    return unless primitive_exists? primitive
    target_role = primitives.fetch(primitive).fetch('meta_attributes', {}).fetch('target-role', {}).fetch('value', 'Started')
    target_role == 'Started'
  end

  # check if pacemaker is online
  # and we can work with it
  # @return [TrueClass,FalseClass]
  def is_online?
    begin
      pcs 'status'
    rescue Puppet::ExecutionFailure => e
      false
    else
      true
    end
  end

  # retry the given block until it returns true
  # or for RETRY_COUNT times with RETRY_STEP sec step
  # raise exception if failed
  def retry_block_until_true
    (0..RETRY_COUNT).each do |count|
      return if yield
      sleep RETRY_STEP
    end
    raise "No success after #{RETRY_COUNT * RETRY_STEP} seconds!"
  end

  # wait for pacemaker to become online
  def wait_for_online
    Puppet.debug "Waiting #{RETRY_COUNT * RETRY_STEP} seconds for Pacemaker to become online"
    retry_block_until_true do
      is_online?
    end
    Puppet.debug 'Pacemaker is online'
  end

  # cleanup a primitive and then wait until
  # we can get it's status again because
  # cleanup blocks operations sections for a while
  # @param primitive [String] primitive name
  def cleanup_with_wait(primitive)
    Puppet.debug "Cleanup primitive #{primitive} and wait until cleanup finishes"
    cleanup_primitive primitive
    retry_block_until_true do
      cib_reset
      !primitive_running?(primitive).nil?
    end
    Puppet.debug = "Primitive #{primitive} have been cleaned up"
  end

  # wait for primitive to start
  # if node is given then start on this node
  # @param primitive [String] primitive id
  # @param node [String] on this node if given
  def wait_for_start(primitive, node = nil)
    message = "Waiting #{RETRY_COUNT * RETRY_STEP} seconds for service '#{primitive}' to start"
    message += " on node '#{node}'" if node
    Puppet.debug message
    retry_block_until_true do
      cib_reset
      primitive_running? primitive, node
    end
    message = "Service '#{primitive}' have started"
    message += " on node '#{node}'" if node
    Puppet.debug message
  end

  # wait for primitive to stop
  # if node is given then start on this node
  # @param primitive [String] primitive id
  # @param node [String] on this node if given
  def wait_for_stop(primitive, node = nil)
    message = "Waiting #{RETRY_COUNT * RETRY_STEP} seconds for service '#{primitive}' to stop"
    message += " on node '#{node}'" if node
    Puppet.debug message
    retry_block_until_true do
      cib_reset
      result = primitive_running? primitive, node
      result.is_a? FalseClass
    end
    message = "Service '#{primitive}' was stopped"
    message += " on node '#{node}'" if node
    Puppet.debug message
  end

end
