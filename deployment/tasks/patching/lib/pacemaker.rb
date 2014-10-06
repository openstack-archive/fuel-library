require 'rexml/document'

module Pacemaker

  @raw_cib = nil
  @cib = nil
  @resources = nil
  @resources_structure = nil

  attr_accessor :raw_cib_file

  def has_pacemaker?
    out,code = run 'which cibadmin 2>&1 1>/dev/null'
    code == 0
  end

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

  def raw_cib
    return File.read raw_cib_file if raw_cib_file
    @raw_cib = `cibadmin -Q`
    if @raw_cib == '' or not @raw_cib
      raise 'Could not dump cib!'
    end
    @raw_cib
  end

  def cib
    @cib = REXML::Document.new(raw_cib)
  end

  def cib_reset
    @raw_cib = nil
    @cib = nil
    @resources = nil
    @resources_structure = nil
    @nodes_structure = nil
  end

  def cib_section_resources
    cib.root.elements['configuration'].elements['resources']
  end

  def cib_section_status
    cib.root.elements['status']
  end

  def cib_section_lrm_rsc_ops(lrm_resource)
    REXML::XPath.match lrm_resource, 'lrm_rsc_op'
  end

  def cib_section_nodes_state
    REXML::XPath.match cib_section_status, 'node_state'
  end

  def cib_section_primitives
    REXML::XPath.match cib_section_resources, 'primitive'
  end

  def determine_resource_status(ops)
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

  def attributes_to_hash(element)
    hash = {}
    element.attributes.each do |a, v|
      hash.store a.to_s, v.to_s
    end
    hash
  end

  def decode_lrm_resources(lrm_resources)
    resources = {}
    lrm_resources.each do |lrm_resource|
      resource = attributes_to_hash lrm_resource
      id = resource['id']
      next unless id
      lrm_rsc_ops = cib_section_lrm_rsc_ops lrm_resource
      ops = decode_lrm_rsc_ops lrm_rsc_ops
      resource.store 'ops', ops
      resource.store 'status', determine_resource_status(ops)
      resources.store id, resource
    end
    resources
  end

  def decode_lrm_rsc_ops(lrm_rsc_ops)
    ops = []
    lrm_rsc_ops.each do |lrm_rsc_op|
      op = attributes_to_hash lrm_rsc_op
      next unless op['call-id']
      ops << op
    end
    ops.sort { |a,b| a['call-id'].to_i <=> b['call-id'].to_i }
  end

  def nodes
    return @nodes_structure if @nodes_structure
    @nodes_structure = {}
    cib_section_nodes_state.each do |node_state|
      node = attributes_to_hash node_state
      id = node['id']
      next unless id
      lrm = node_state.elements['lrm']
      lrm_resources = REXML::XPath.match lrm, 'lrm_resources/lrm_resource'
      resources = decode_lrm_resources lrm_resources
      node.store 'resources', resources
      @nodes_structure.store id, node
    end
    @nodes_structure
  end

  def resources
    return @resources_structure if @resources_structure
    @resources_structure = {}
      cib_section_primitives.each do |primitive|
      primitive_structure = {}
      id = primitive.attributes['id']
      next unless id
      primitive_structure.store :name, id
      primitive.attributes.each do |k, v|
        primitive_structure.store k.to_sym, v
      end
      if primitive.parent.name and primitive.parent.attributes['id']
        parent_structure = {
            :id => primitive.parent.attributes['id'],
            :type => primitive.parent.name
        }
        primitive_structure.store :name, parent_structure[:id]
        primitive_structure.store :parent, parent_structure
      end
      @resources_structure.store id, primitive_structure
    end
    @resources_structure
  end

  def get_resources_names
    resources.map do |id, value|
      value[:name]
    end
  end

  def get_resources_by_regexp(regexp)
    matched = {}
    resources.each do |id, value|
      matched.store id, value if value[:name] =~ regexp
    end
    matched
  end

  def get_resources_names_by_regexp(regexp)
    get_resources_by_regexp(regexp).map do |id, value|
      value[:name]
    end
  end

  def stop_resources_by_regexp(regexp)
    get_resources_names_by_regexp(regexp).each do |r|
      stop_resource r
    end
  end

  def start_resources_by_regexp(regexp)
    get_resources_names_by_regexp(regexp).each do |r|
      start_resource r
    end
  end

  def ban_resources_by_regexp(regexp)
    get_resources_names_by_regexp(regexp).each do |r|
      ban_resource r
    end
  end

  def unban_resources_by_regexp(regexp)
    get_resources_names_by_regexp(regexp).each do |r|
      unban_resource r
    end
  end

  def stop_resource(value)
    run "crm resource stop '#{value}'"
  end

  def start_resource(value)
    run "crm resource start '#{value}'"
  end

  def ban_resource(value)
    run "pcs resource ban '#{value}'"
  end

  def unban_resource(value)
    run "pcs resource clear '#{value}'"
  end

  def cleanup_resource(value)
    run "crm resource cleanup '#{value}'"
  end

  def manage_resource(value)
    run "crm resource manage '#{value}'"
  end

  def unmanage_resource(value)
    run "crm resource unmanage '#{value}'"
  end

  def pcmk_status
    sleep 2
    run 'pcs status'
    sleep 2
  end

  def stop_or_ban_by_regexp(regexp)
    if not controllers_count or controllers_count == 1
      stop_resources_by_regexp regexp
    else
      ban_resources_by_regexp regexp
    end
  end

  def start_or_unban_by_regexp(regexp)
    if not controllers_count or controllers_count == 1
      start_resources_by_regexp regexp
    else
      unban_resources_by_regexp regexp
    end
  end

  def cleanup_resources_by_regexp(regexp)
    get_resources_names_by_regexp(regexp).each do |r|
      cleanup_resource r
    end
  end

  def manage_cluster
    maintenance_mode true
  end

  def unmanage_cluster
    maintenance_mode false
  end

  def maintenance_mode(value)
    value = !!value
    xml=<<-eos
<diff>
  <diff-added>
    <cib>
      <configuration>
        <crm_config>
          <cluster_property_set id="cib-bootstrap-options">
            <nvpair id="cib-bootstrap-options-maintenance-mode" name="maintenance-mode" value="#{value}"/>
          </cluster_property_set>
        </crm_config>
      </configuration>
    </cib>
  </diff-added>
</diff>
    eos
    apply_xml xml
  end

  def apply_xml(xml)
    xml.gsub! "\n", ' '
    xml.gsub! /\s+/, ' '
    run "cibadmin --patch --sync-call --xml-text '#{xml}'"
  end

  def primitive_status(primitive, node = nil)
    if node
      nodes.
          fetch(node, {}).
          fetch('resources',{}).
          fetch(primitive, {}).
          fetch('status', nil)
    else
      statuses = []
      nodes.each do |k,v|
        status = v.fetch('resources',{}).
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

  def primitive_running?(primitive, node = nil)
    status = primitive_status primitive, node
    return unless status
    %w(start master).include? status
  end

end
