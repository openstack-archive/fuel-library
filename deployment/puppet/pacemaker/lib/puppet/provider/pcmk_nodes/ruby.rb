require File.join File.dirname(__FILE__), '../pacemaker_common.rb'

Puppet::Type.type(:pcmk_nodes).provide(:ruby, :parent => Puppet::Provider::Pacemaker_common) do

  commands 'cmapctl'  => '/usr/sbin/corosync-cmapctl'
  commands 'cibadmin' => '/usr/sbin/cibadmin'
  commands 'crm_node' => '/usr/sbin/crm_node'

  def node_name
    return @node_name if @node_name
    @node_name = crm_node('-n').chomp.strip
  end

  def cmapctl_nodelist
    cmapctl '-b', 'nodelist.node'
  end

  def cmapctl_safe(*args)
    if @resource[:debug]
      debug (['cmapctl'] + args).join ' '
      return
    end
    cmapctl *args
  end

  def cibadmin_safe(*args)
    if @resource[:debug]
      debug (['cibadmin'] + args).join ' '
      return
    end
    cibadmin *args
  end

  ###################################

  def corosync_nodes_structure
    return @corosync_nodes_structure if @corosync_nodes_structure
    nodes = {}
    cmapctl_nodelist.split("\n").each do |line|
      if line =~ %r(^nodelist\.node\.(\d+)\.nodeid\s+\(u32\)\s+=\s+(\d+))
        node_number = $1
        node_nodeid = $2
        nodes[node_number] = {} unless nodes[node_number]
        nodes[node_number]['id'] = node_nodeid
        nodes[node_number]['number'] = node_number
        node_name = node_data_by_id.fetch(node_nodeid, {}).fetch 'name', nil
        nodes[node_number]['uname'] = node_name if node_name
      end
      if line =~ %r(^nodelist\.node\.(\d+)\.ring(\d+)_addr\s+\(str\)\s+=\s+(\S+))
        node_number = $1
        node_ring_number = $2
        node_ip_addr = $3
        nodes[node_number] = {} unless nodes[node_number]
        nodes[node_number]['ip'] = node_ip_addr
      end
    end
    @corosync_nodes_structure = {}
    nodes.each do |number, node|
      name = node['uname']
      next unless name
      @corosync_nodes_structure.store name, node
    end
    @corosync_nodes_structure
  end

  def pcmk_nodes_reset
    @corosync_nodes_structure = nil
    @node_name = nil
  end

  ###

  def change_fqdn_to_name?
    begin
      return false if nodes_data.keys.include? node_name
      return true if nodes_data.keys.map { |fqdn| fqdn.split('.').first }.include? node_name
      false
    rescue
      false
    end
  end

  def change_fqdn_to_name
    debug 'Changing Pacemaker node names from FQDNs to Hostnames'
    nodes = {}
    @resource[:nodes].each do |fqdn, ip|
      name = fqdn.split('.').first
      nodes.store name, ip
    end
    @resource[:nodes] = nodes
    @resource[:pacemaker_nodes] = nodes
    @resource[:corosync_nodes] = nodes
    pcmk_nodes_reset
  end

  ###

  def pacemaker_nodes_structure
    node_ids
  end

  def node_data_by_id
    data = {}
    nodes_data.each do |name, node|
      next unless node.is_a? Hash
      id = node['id']
      node['name'] = name
      next unless id
      data[id] = node
    end
    data
  end

  def nodes_data
    @resource[:nodes]
  end

  def remove_pacemaker_node(node_name)
    remove_pacemaker_node_record node_name
    remove_pacemaker_node_state node_name
    purge_node_locations node_name
  end

  def add_pacemaker_node(node_name)
    node_id = nodes_data.fetch(node_name, {}).fetch 'id', nil
    fail "Could not get all the data for the new pacemaker node '#{node_name}'!" unless node_id
    add_pacemaker_node_record node_name, node_id
    add_pacemaker_node_state node_name, node_id
  end

  def remove_pacemaker_node_record(node_name)
    cibadmin_safe '--delete', '--obj_type', 'nodes', '--crm_xml', "<node uname='#{node_name}'/>"
  end

  def remove_pacemaker_node_state(node_name)
    cibadmin_safe '--delete', '--obj_type', 'status', '--crm_xml', "<node_state uname='#{node_name}'/>"
  end

  def remove_location_constraint(constraint_id)
    cibadmin_safe '--delete', '--obj_type', 'constraints', '--crm_xml',  "<rsc_location id='#{constraint_id}'/>"
  end

  def add_pacemaker_node_record(node_name, node_id)
    patch = <<-eos
<diff>
  <diff-added>
    <cib>
      <configuration>
        <nodes>
          <node id="#{node_id}" uname="#{node_name}" __crm_diff_marker__="added:top"/>
        </nodes>
      </configuration>
    </cib>
  </diff-added>
</diff>
    eos
    cibadmin_safe '--patch', '--sync-call', '--xml-text', patch
  end

  def add_pacemaker_node_state(node_name, node_id)
    patch = <<-eos
<diff>
  <diff-added>
    <cib>
      <status>
        <node_state id="#{node_id}" uname="#{node_name}" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member" __crm_diff_marker__="added:top"/>
      </status>
    </cib>
  </diff-added>
</diff>
    eos
    cibadmin_safe '--patch', '--sync-call', '--xml-text', patch
  end

  def remove_corosync_node(node_name)
    node_number = corosync_nodes_structure[node_name]['number']
    fail "Could not get node_number of '#{node_name}' node!" unless node_number
    remove_corosync_node_record node_number
  end

  def remove_corosync_node_record(node_number)
    begin
      cmapctl_safe '-D', "nodelist.node.#{node_number}"
    rescue => e
      debug "Failed: #{e.message}"
    end
  end

  def add_corosync_node(node_name)
    node = nodes_data.fetch node_name, {}
    node_id = node.fetch 'id', nil
    node_ip = node.fetch 'ip', nil
    fail "Could not get all the data for the new corosync node '#{node_name}'!" unless node_id and node_ip
    add_corosync_node_record node_id, node_ip, node_id
  end

  def add_corosync_node_record(node_number=nil, node_addr=nil, node_id=nil, ring_number=0)
    cmapctl_safe '-s', "nodelist.node.#{node_number}.nodeid", 'u32', "#{node_id}"
    cmapctl_safe '-s', "nodelist.node.#{node_number}.ring#{ring_number}_addr", 'str', "#{node_addr}"
  end

  def purge_node_locations(node_name)
    debug "Call: purge all location constraints for node: '#{node_name}'"
    constraint_locations.each do |constraint_id, constraint|
      next unless constraint['node'] == node_name
      remove_location_constraint constraint_id
    end
  end

  def compare_hashes_by_keys(hash1, hash2, keys=nil)
    return hash1 == hash2 unless keys
    keys = [keys] unless keys.is_a? Array
    filtered_hash1 = hash1.select { |key, value| keys.include? key.to_s }
    filtered_hash2 = hash2.select { |key, value| keys.include? key.to_s }
    filtered_hash1 == filtered_hash2
  end

  #################

  def corosync_nodes
    debug 'Call: corosync_nodes'
    change_fqdn_to_name if change_fqdn_to_name?
    debug "Return: #{corosync_nodes_structure.inspect}"
    corosync_nodes_structure
  end

  def corosync_nodes=(expected_nodes)
    debug "Call: corosync_nodes='#{expected_nodes.inspect}'"
    existing_nodes = corosync_nodes_structure

    if @resource[:remove_corosync_nodes]
      existing_nodes.each do |existing_node_name, existing_node|
        next if expected_nodes.find do |expected_node_name, expected_node|
          compare_hashes_by_keys existing_node, expected_node, %w(id ip)
        end
        remove_corosync_node existing_node_name
      end
    end

    if @resource[:add_corosync_nodes]
      expected_nodes.each do |expected_node_name, expected_node|
        next if existing_nodes.find do |existing_node_name, existing_node|
          compare_hashes_by_keys expected_node, existing_node, %w(id ip)
        end
        add_corosync_node expected_node_name
      end
    end
  end

  def pacemaker_nodes
    debug 'Call: pacemaker_nodes'
    change_fqdn_to_name if change_fqdn_to_name?
    debug "Return: #{pacemaker_nodes_structure.inspect}"
    pacemaker_nodes_structure
  end

  def pacemaker_nodes=(expected_nodes)
    debug "Call: pacemaker_nodes='#{expected_nodes.inspect}'"
    existing_nodes = pacemaker_nodes_structure

    if @resource[:remove_pacemaker_nodes]
      existing_nodes.each do |existing_node_name, existing_node|
        next if expected_nodes.find do |expected_node_name, expected_node|
          compare_hashes_by_keys existing_node, expected_node, 'id'
        end
        remove_pacemaker_node existing_node_name
      end
    end

    if @resource[:add_pacemaker_nodes]
      expected_nodes.each do |expected_node_name, expected_node|
        #next if existing_nodes.include? node
        next if existing_nodes.find do |existing_node_name, existing_node|
          compare_hashes_by_keys expected_node, existing_node, 'id'
        end
        add_pacemaker_node expected_node_name
      end
    end
  end

end
