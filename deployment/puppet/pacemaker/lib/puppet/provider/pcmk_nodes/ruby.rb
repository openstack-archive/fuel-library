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
        node_name = pacemaker_node_id_to_name node_nodeid
        nodes[node_number]['uname'] = node_name if node_name
      end
      if line =~ %r(^nodelist\.node\.(\d+)\.ring(\d+)_addr\s+\(str\)\s+=\s+(\S+))
        node_number = $1
        node_ring_number = $2
        node_ip_addr = $3
        nodes[node_number] = {} unless nodes[node_number]
        ring = "ring#{node_ring_number}_addr"
        nodes[node_number][ring] = node_ip_addr
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
    @resource[:pacemaker_nodes] = @resource[:nodes].keys
    @resource[:corosync_nodes] = @resource[:nodes].keys
    pcmk_nodes_reset
  end

  ###

  def pacemaker_nodes_structure
    node_ids
  end

  def pacemaker_node_id_to_name(id)
    pacemaker_nodes_structure.invert[id]
  end

  def generate_new_node(node_name)
    return corosync_nodes_structure[node_name] if corosync_nodes_structure[node_name]
    ip = nodes_data[node_name]

    @corosync_nodes_structure[node_name] = {
        'uname' => node_name,
        'id' => next_pacemaker_node_id,
        'number' => next_corosync_node_number,
        'ring0_addr' => ip,
    }
    @corosync_nodes_structure[node_name]
  end

  def next_corosync_node_number
    number = corosync_nodes_structure.inject(0) do |max, node|
      number = node.last['number'].to_i
      max = number if number > max
      max
    end
    number += 1
    number.to_s
  end

  def next_pacemaker_node_id
    id = corosync_nodes_structure.inject(0) do |max, node|
      id = node.last['id'].to_i
      max = id if id > max
      max
    end
    id += 1
    id.to_s
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
    node_id = generate_new_node(node_name)['id']
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
    cmapctl_safe '-D', "nodelist.node.#{node_number}"
  end

  def add_corosync_node(node_name)
    node = generate_new_node node_name
    unless node['number'] and nodes_data[node_name] and node['id']
      fail "Could not get all the data for the  new node '#{node_name}' (#{node['number']}, #{nodes_data[node_name]}, #{node['id']})"
    end
    add_corosync_node_record node['number'], nodes_data[node_name], node['id']
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

  #################

  def corosync_nodes
    debug 'Call: corosync_nodes'
    change_fqdn_to_name if change_fqdn_to_name?
    corosync_nodes_structure.keys
  end

  def corosync_nodes=(expected_nodes)
    debug "Call: corosync_nodes='#{expected_nodes.inspect}'"
    existing_nodes = corosync_nodes_structure.keys

    # remove unexpected nodes
    existing_nodes.each do |node|
      next if expected_nodes.include? node
      remove_corosync_node node
    end

    # add missing nodes
    expected_nodes.each do |node|
      next if existing_nodes.include? node
      add_corosync_node node
    end
  end

  def pacemaker_nodes
    debug 'Call: pacemaker_nodes'
    change_fqdn_to_name if change_fqdn_to_name?
    pacemaker_nodes_structure.keys
  end

  def pacemaker_nodes=(expected_nodes)
    debug "Call: pacemaker_nodes='#{expected_nodes.inspect}'"
    existing_nodes = pacemaker_nodes_structure.keys

    # remove unexpected nodes
    existing_nodes.each do |node|
      next if expected_nodes.include? node
      remove_pacemaker_node node
    end

    # add missing nodes
    expected_nodes.each do |node|
      next if existing_nodes.include? node
      add_pacemaker_node node
    end
  end

end
