require File.join File.dirname(__FILE__), '../pacemaker_common.rb'

Puppet::Type.type(:pcmk_nodes).provide(:ruby, :parent => Puppet::Provider::Pacemaker_common) do

  commands 'cmapctl'  => '/usr/sbin/corosync-cmapctl'
  commands 'cibadmin' => '/usr/sbin/cibadmin'

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

  def pacemaker_nodes_structure
    node_ids
  end

  def pacemaker_node_id_to_name(id)
    pacemaker_nodes_structure.invert[id]
  end

  def highest_corosync_node_number
    corosync_nodes_structure.inject(0) do |max, node|
      number = node.last['number'].to_i
      max = number if number > max
      max
    end
  end

  def highest_pacemaker_node_id
    pacemaker_nodes_structure.inject(0) do |max, node|
      number = node.last.to_i
      max = number if number > max
      max
    end
  end

  def nodes_data
    @resource[:nodes]
  end

  def remove_pacemaker_node(node_name)
    remove_pacemaker_node_record node_name
    remove_pacemaker_node_state node_name
    purge_node_locations node_name
  end

  def remove_pacemaker_node_record(node_name)
    cibadmin_safe '--delete', '--obj_type', 'nodes', '--crm_xml', "<node uname='#{node_name}'/>"
  end

  def remove_pacemaker_node_state(node_name)
    cibadmin_safe '--delete', '--obj_type', 'status', '--crm_xml', "<node_state uname='#{node_name}'/>"
  end

  def remove_location_constraint(constraint_id)
    cibadmin_safe '--delete', '--obj_type', 'constraints' '--crm_xml',  "<rsc_location id='#{constraint_id}'/>"
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
    node_number = highest_corosync_node_number + 1
    node_addr = nodes_data[node_name]
    node_id = highest_pacemaker_node_id + 1
    unless node_number and node_addr and node_id
      fail "Could not get all the data for the  new node '#{node_name}' (#{node_number}, #{node_addr}, #{node_id})"
    end
    add_corosync_node_record node_number, node_addr, node_id
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
    corosync_nodes_structure.keys
  end

  def corosync_nodes=(expected_nodes)
    debug "Call: corosync_nodes='#{expected_nodes.inspect}'"
    existing_nodes = corosync_nodes_structure.keys

    existing_nodes.each do |node|
      next if expected_nodes.include? node
      remove_corosync_node node
    end

    expected_nodes.each do |node|
      next if existing_nodes.include? node
      add_corosync_node node
    end
  end

  ##

  def pacemaker_nodes
    debug 'Call: pacemaker_nodes'
    pacemaker_nodes_structure.keys
  end

  def pacemaker_nodes=(expected_nodes)
    debug "Call: pacemaker_nodes='#{expected_nodes.inspect}'"
    existing_nodes = pacemaker_nodes_structure.keys

    existing_nodes.each do |node|
      next if expected_nodes.include? node
      remove_pacemaker_node node
    end
  end

end
