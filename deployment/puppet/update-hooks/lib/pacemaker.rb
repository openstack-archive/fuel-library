require 'rexml/document'

module Pacemaker

  @raw_cib = nil
  @cib = nil
  @primitives = nil
  @primitives_structure = nil

  attr_accessor :raw_cib_file

  # check if pacemaker is installed
  # @return [TrueClass,FalseClass]
  def has_pacemaker?
    out,code = run 'which cibadmin 2>&1 1>/dev/null'
    code == 0
  end

  # get controller count frpm astute.yaml data
  # @return [Numeric] the number of controller nodes
  def controllers_count
    return nil unless fuel_settings.is_a? Hash and fuel_settings.key? 'nodes'
    nodes = fuel_settings['nodes']
    return nil unless nodes.is_a? Array
    nodes.inject(0) do |controllers, node|
      if node['role'] =~ /controller/
        controllers + 1
      else
        controllers
      end
    end
  end

  # determine if deployment mode is ha in astute yaml data
  # @return [TrueClass,FalseClass]
  def is_ha?
    return nil unless fuel_settings.is_a? Hash and fuel_settings.key? 'deployment_mode'
    if %w(singlenode multinode).include? fuel_settings['deployment_mode']
      false
    elsif %w(ha ha_compact ha_full).include? fuel_settings['deployment_mode']
      true
    else
      nil
    end
  end

  # get a raw CIB from cibadmin
  # or from a debug file if raw_cib_file is set
  # @return [String] cib xml
  def raw_cib
    return File.read raw_cib_file if raw_cib_file
    @raw_cib = `cibadmin -Q`
    if @raw_cib == '' or not @raw_cib
      raise 'Could not dump cib!'
    end
    @raw_cib
  end

  # create a new REXML CIB document
  # @return [REXML::Document] at '/'
  def cib
    @cib = REXML::Document.new(raw_cib)
  end

  # reset all saved variables to obtain new data
  def cib_reset
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
    status = '?'
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

  # get array of primitives names
  # @return [Array<String>]
  def get_primitives_names
    names = []
    primitives.each do |id, value|
      names << value['name']
    end
    names
  end

  # get array of primitives ids
  # @return [Array<String>]
  def get_primitives_ids
    names = []
    primitives.each do |id, value|
      names << value['id']
    end
    names
  end

  # get primitives structures which names match the regex
  # @param regexp [Regexp]
  # @return [Hash<String => Hash>]
  def get_primitives_by_regexp(regexp)
    matched = {}
    primitives.each do |id, value|
      matched.store id, value if value['name'] =~ regexp
    end
    matched
  end

  # get primitives names array which match the regexp
  # @param regexp [Regexp]
  # @return [Array<String>]
  def get_primitives_names_by_regexp(regexp)
    get_primitives_by_regexp(regexp).map do |id, value|
      value['name']
    end
  end

  # stop primitives which name match the regexp
  # @param regexp [Regexp]
  def stop_primitives_by_regexp(regexp)
    get_primitives_names_by_regexp(regexp).each do |r|
      stop_primitive r
    end
  end

  # start primitives which name match the regexp
  # @param regexp [Regexp]
  def start_primitives_by_regexp(regexp)
    get_primitives_names_by_regexp(regexp).each do |r|
      start_primitive r
    end
  end

  # ban primitives which name match the regexp
  # @param regexp [Regexp]
  def ban_primitives_by_regexp(regexp)
    get_primitives_names_by_regexp(regexp).each do |r|
      ban_primitive r
    end
  end

  # unban primitives which name match the regexp
  # @param regexp [Regexp]
  def unban_primitives_by_regexp(regexp)
    get_primitives_names_by_regexp(regexp).each do |r|
      unban_primitive r
    end
  end

  # stop this primitive
  # @param value [String]
  def stop_primitive(value)
    run 'pcs resource meta value target-role=Stopped'
  end

  # start this primitive
  # @param value [String]
  def start_primitive(value)
    run 'pcs resource meta value target-role=Started'
  end

  # ban this primitive
  # @param value [String]
  def ban_primitive(value)
    run "pcs resource ban '#{value}'"
  end

  # move this primitive
  # @param value [String]
  def move_primitive(value)
    run "pcs resource move '#{value}'"
  end

  # unban or unmove this primitive
  # @param value [String]
  def unban_primitive(value)
    run "pcs resource clear '#{value}'"
  end
  alias :clear :unban_primitive
  alias :unmove :unban_primitive

  # cleanup this primitive
  # @param value [String]
  def cleanup_primitive(value)
    run "pcs resource cleanup '#{value}'"
  end

  # manage this primitive
  # @param value [String]
  def manage_primitive(value)
    run "pcs resource manage '#{value}'"
  end

  # unamanage this primitive
  # @param value [String]
  def unmanage_primitive(value)
    run "pcs resource unmanage '#{value}'"
  end

  # view pacemaker status
  def pcmk_status
    run 'pcs status'
  end

  # stop primitives on single controller cluster
  # of ban on multi controller cluster by regexp
  # @param regexp [Regexp]
  def stop_or_ban_by_regexp(regexp)
    if not controllers_count or controllers_count == 1
      stop_primitives_by_regexp regexp
    else
      ban_primitives_by_regexp regexp
    end
  end

  # start primitives on single controller cluster
  # of unban on multi controller cluster by regexp
  # @param regexp [Regexp]
  def start_or_unban_by_regexp(regexp)
    if not controllers_count or controllers_count == 1
      start_primitives_by_regexp regexp
    else
      unban_primitives_by_regexp regexp
    end
  end

  # cleanup primitives whose name match regexp
  # @param regexp [Regexp]
  def cleanup_by_regexp(regexp)
    get_primitives_names_by_regexp(regexp).each do |r|
      cleanup_primitive r
    end
  end

  # set cluster to maintenance
  def manage_cluster
    maintenance_mode true
  end

  # return cluster from maintenance mode
  def unmanage_cluster
    maintenance_mode false
  end

  # set quorum_policy of the cluster
  # @param value [String]
  def no_quorum_policy(value)
    run "pcs property set no-quorum-policy=#{value}"
  end

  # set maintenance_mode of the cluster
  # @param value [TrueClass,FalseClass]
  def maintenance_mode(value)
    run "pcs property set maintenance-mode=#{value}"
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

  # determine if a primitive is running on the entire cluster
  # of on a node if node name param given
  # @param primitive [String]
  # @param node [String]
  # @return [TrueClass,FalseClass]
  def primitive_running?(primitive, node = nil)
    status = primitive_status primitive, node
    return unless status
    %w(start master).include? status
  end

  # check if primitive is clone or multistate
  # @param id [String] primitive id
  # @return [TrueClass,FalseClass]
  def primitive_is_complex?(id)
    return nil unless primitives.key? id
    primitives[id].key? 'parent'
  end

end
