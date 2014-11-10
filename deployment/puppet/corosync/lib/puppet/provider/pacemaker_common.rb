require 'rexml/document'

class Puppet::Provider::Pacemaker_common < Puppet::Provider

  @cib = nil
  @primitives = nil
  @primitives_structure = nil

  RETRY_COUNT = 360
  RETRY_STEP = 5

  # CIB and its sections
  ######################

  # create a new REXML CIB document
  # @return [REXML::Document] at '/'
  def cib
    return @cib if @cib
    @cib = REXML::Document.new(raw_cib)
  end

  # reset all saved variables to obtain new data
  def cib_reset
    # debug 'Reset CIB memoization'
    @raw_cib = nil
    @cib = nil
    @primitives = nil
    @primitives_structure = nil
    @constraints_structure = nil
    @nodes_structure = nil
    @cluster_properties_structure = nil
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
    REXML::XPath.match constraint, 'rule'
  end

  # get cluster property CIB section
  # @return [REXML::Element]
  def cib_section_cluster_property
    REXML::XPath.match(cib, '/cib/configuration/crm_config/cluster_property_set').first
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
          'stop'   => 0,
          'start'  => 1,
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
        parent_structure = {
            'id'   => primitive.parent.attributes['id'],
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

  # check if primitive exists in the confiuguration
  # @param primitive primitive id or name
  def primitive_exists?(primitive)
    primitives.key? primitive
  end

  # check if primitive is clone or multistate
  # @param primitive [String] primitive id
  # @return [TrueClass,FalseClass]
  def primitive_is_complex?(primitive)
    return unless primitive_exists? primitive
    primitives[primitive].key? 'parent'
  end

  # check if primitive is clone
  # @param primitive [String] primitive id
  # @return [TrueClass,FalseClass]
  def primitive_is_clone?(primitive)
    is_complex = primitive_is_complex? primitive
    return is_complex unless is_complex
    primitives[primitive]['parent']['type'] == 'clone'
  end

  # check if primitive is multistate
  # @param primitive [String] primitive id
  # @return [TrueClass,FalseClass]
  def primitive_is_multistate?(primitive)
    is_complex = primitive_is_complex? primitive
    return is_complex unless is_complex
    primitives[primitive]['parent']['type'] == 'master'
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

  # Basic actions
  ###############

  # get the raw CIB from Pacemaker
  # @return [String] cib xml
  def raw_cib
    @raw_cib = cibadmin '-Q'
    if ! @raw_cib or @raw_cib == ''
      fail 'Could not dump CIB XML!'
    end
    @raw_cib
  end

  # check if pacemaker is online
  # and we can work with it
  # @return [TrueClass,FalseClass]
  def is_online?
    begin
      cibadmin '-Q'
      true
    rescue Puppet::ExecutionFailure
      false
    else
      true
    end
  end

  # sets the meta attribute of a primitive
  # @param primitive [String] primitive's id
  # @param attribute [String] atttibute's name
  # @param value [String] attribute's value
  def set_primitive_meta_attribute(primitive, attribute, value)
    options = [ '--quiet', '--resource', primitive ]
    options += [ '--set-parameter', attribute, '--meta', '--parameter-value', value ]
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
    options = [ '--quiet', '--resource', primitive, '--node', node ]
    options += [ '--ban' ]
    retry_block { crm_resource options }
  end

  # unban this primitive
  # @param primitive [String] what primitive to unban
  # @param node [String] on which node this primitive should be unbanned
  def unban_primitive(primitive, node)
    options = [ '--quiet', '--resource', primitive, '--node', node ]
    options += [ '--clear' ]
    retry_block { crm_resource options }
  end
  alias :clear_primitive :unban_primitive

  # move this primitive
  # @param primitive [String] what primitive to un-move
  # @param node [String] to which node the primitive should be moved
  def move_primitive(primitive, node)
    options = [ '--quiet', '--resource', primitive, '--node', node ]
    options += [ '--move' ]
    retry_block { crm_resource options }
  end

  # un-move this primitive
  # @param primitive [String] what primitive to un-move
  # @param node [String] from which node the primitive should be un-moved
  def unmove_primitive(primitive, node)
    options = [ '--quiet', '--resource', primitive, '--node', node ]
    options += [ '--un-move' ]
    retry_block { crm_resource options }
  end

  # cleanup this primitive
  # @param primitive [String] what primitive to cleanup
  # @param node [String] on which node to cleanup (optional)
  # cleanups on every node if node is not given
  def cleanup_primitive(primitive, node = nil)
    options = [ '--quiet', '--resource', primitive ]
    options += [ '--node', node ] if node
    options += [ '--cleanup' ]
    retry_block { crm_resource options }
  end

  # apply the XML patch to CIB
  # @param xml [String] the patch to apply
  def apply_cib_patch(xml)
    retry_block { cibadmin '--patch', '--sync-call', '--xml-text', xml }
  end

  # Constraints actions
  #####################

  # parse constraint rule elements to the rule structure
  # @param element [REXML::Element]
  # @return [Hash<String => Hash>]
  def decode_constraint_rules(element)
    rules = cib_section_constraint_rules element
    return {} unless rules.any?
    rules_structure = {}
    rules.each do |rule|
      rule_structure = attributes_to_hash rule
      id = rule_structure['id']
      next unless id
      rule_expressions = elements_to_hash rule, 'id'
      rule_structure.store 'expressions', rule_expressions if rule_expressions
      rules_structure.store id, rule_structure
    end
    rules_structure
  end

  # get primitives configuration structure with primitives and their attributes
  # @return [Hash<String => Hash>]
  def constraints
    return @constraints_structure if @constraints_structure
    @constraints_structure = {}
    cib_section_constraints.each do |constraint|
      id = constraint.attributes['id']
      next unless id
      constraint_structure = attributes_to_hash constraint

      xml = constraint.to_s
      constraint_type = nil
      if xml.start_with? '<rsc_location'
        constraint_type = 'location'
      elsif xml.start_with? '<rsc_order'
        constraint_type = 'order'
      elsif xml.start_with? '<rsc_colocation'
        constraint_type = 'colocation'
      end
      constraint_structure.store 'type', constraint_type if constraint_type

      rules = decode_constraint_rules constraint
      constraint_structure.store 'rules', rules

      @constraints_structure.store id, constraint_structure
    end
    @constraints_structure
  end

  # check if constaint with specified id exists
  # @param id [String]
  # @return [TrueClass,FalseClass]
  def constraint_exists?(id)
    constraints.key? id.to_s
  end

  # construct the constraint unique name
  # from primitive's and node's names
  # @param primitive [String]
  # @param node [String]
  # @return [String]
  def constraint_location_name(primitive, node)
    "#{primitive}-on-#{node}"
  end

  # add a location constraint
  # @param primitive [String] the primitive's name
  # @param node [String] the node's name
  # @param score [Numeric,String] score value
  def constraint_location_add(primitive, node, score = 100)
    id = constraint_location_name primitive, node
    xml = <<-EOF
    <diff>
      <diff-added>
        <cib>
          <configuration>
            <constraints>
              <rsc_location id="#{id}" node="#{node}" rsc="#{primitive}" score="#{score}"/>
            </constraints>
          </configuration>
        </cib>
      </diff-added>
    </diff>
    EOF
    apply_cib_patch xml
  end

  # remove a location constraint
  # @param primitive [String] the primitive's name
  # @param node [String] the node's name
  # @param score [Numeric,String] score value
  def constraint_location_remove(primitive, node, score = 100)
    id = constraint_location_name primitive, node
    xml = <<-EOF
    <diff>
      <diff-removed>
        <cib>
          <configuration>
            <constraints>
              <rsc_location id="#{id}" node="#{node}" rsc="#{primitive}" score="#{score}"/>
            </constraints>
          </configuration>
        </cib>
      </diff-removed>
    </diff>
    EOF
    apply_cib_patch xml
  end

  # check if locations constraint for this primitive is
  # present on this node
  # @param primitive [String] the primitive's name
  # @param node [String] the node's name
  # @return [TrueClass,FalseClass]
  def constraint_location_exists?(primitive, node)
    id = constraint_location_name primitive, node
    constraint_exists? id
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

  # retry the given block until it runs without
  # exceptions of return true
  # or for RETRY_COUNT times with RETRY_STEP sec step
  # print cluster status report on fail
  # @param options [Hash]
  # :count [Integer] how many times to retry
  # :step [Integer] how long to wait between retries
  # :fail_on_timeout [true,false] raise error on timeout? (default: true)
  # :false_is_failure [true,false] count false or nil return values as failure? (default: true)
  def retry_block(options = {})
    default_options = {
      :count             => RETRY_COUNT,
      :step              => RETRY_STEP,
      :fail_on_timeout   => true,
      :false_is_failure  => true,
    }
    options = default_options.merge options

    options[:count].times do
      begin
        out = yield
        if options[:false_is_failure]
          return out if out
        else
          return out
        end
      rescue => e
        Puppet.debug "Execution failure: #{e.message}"
      end
      sleep options[:step]
    end
    debug cluster_debug_report
    fail "Execution timeout after #{options[:count] * options[:step]} seconds!" if options[:fail_on_timeout]
  end

  # wait for pacemaker to become online
  def wait_for_online
    debug "Waiting #{RETRY_COUNT * RETRY_STEP} seconds for Pacemaker to become online"
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
    message = "Waiting #{RETRY_COUNT * RETRY_STEP} seconds for service '#{primitive}' to start"
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
    message = "Waiting #{RETRY_COUNT * RETRY_STEP} seconds for service '#{primitive}' to start master"
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
    message = "Waiting #{RETRY_COUNT * RETRY_STEP} seconds for service '#{primitive}' to stop"
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
    show_properties = %w(
        symmetric-cluster
        no-quorum-policy
        expected-quorum-votes
        start-failure-is-fatal
        stonith-enabled
        last-lrm-refresh
      )
    show_properties.each do |p|
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
    @cluster_properties_structure = elements_to_hash cib_section_cluster_property, 'name'
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
    options = [ '--quiet', '--type', 'crm_config', '--name', property_name ]
    options += [ '--update', property_value ]
    retry_block { crm_attribute options }
  end

  # delete this cluster's property
  # @param property_name [String] the name of the property
  def cluster_property_delete(property_name)
    options = [ '--quiet', '--type', 'crm_config', '--name', property_name ]
    options += [ '--delete' ]
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

end
