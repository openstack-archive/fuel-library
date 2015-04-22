require File.join File.dirname(__FILE__), '../pacemaker_common.rb'

Puppet::Type.type(:pcmk_nodes).provide(:ruby, :parent => Puppet::Provider::Pacemaker_common) do

  commands 'cmapctl'  => '/usr/sbin/corosync-cmapctl'
  commands 'cibadmin' => '/usr/sbin/cibadmin'

  def cmapctl_nodelist
    cmapctl '-b', 'nodelist.node'
  end

  def cmapctl_safe(*args)
    puts 'cmapctl ' + args.join(' ')
  end

  def cibadmin_safe(*args)
    puts 'cibadmin ' + args.join(' ')
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
    return @pacemaker_nodes_structure if @pacemaker_nodes_structure
    @pacemaker_nodes_structure = node_ids
  end

  def pacemaker_node_id_to_name(id)
    pacemaker_nodes_structure.invert[id]
  end

  #################

  def remove_pacemaker_node(node_name)
    cibadmin_safe '--delete', '--obj_type', 'nodes', '--crm_xml', "<node uname='#{node_name}'/>"
    cibadmin_safe '--delete', '--obj_type', 'status', '--crm_xml', "<node_state uname='#{node_name}'/>"
    purge_node_locations node_name
  end

  def remove_corosync_node(node_name)
    node_number = corosync_nodes_structure[node_name]['number']
    fail "Could not get node_number of '#{node_name}' node!" unless node_number
    cmapctl_safe '-D', "nodelist.node.#{node_number}"
  end

  def add_corosync_node(node_name, node_number=1, node_id=1, node_addr=1, ring_number=0)
    # TODO calculate node_id=1, node_addr=1 node_number=1,
    cmapctl_safe '-s', "nodelist.node.#{node_number}.nodeid", 'u32', "#{node_id}"
    cmapctl_safe '-s', "nodelist.node.#{node_number}.ring#{ring_number}_addr", 'str', "#{node_addr}"
  end

  def purge_node_locations(node_name)
    debug "Call: purge all location constraints for node: '#{node_name}'"
  end

  #################

  def corosync_nodes
    debug 'Call: corosync_nodes'
    corosync_nodes_structure.keys
  end

  def corosync_nodes=(expected_nodes)
    debug "Call: corosync_nodes='#{expected_nodes.inspect}'"
    existing_nodes = corosync_nodes_structure.keys
    # remove unexpected existing nodes
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

  ##

  def pacemaker_nodes
    debug 'Call: pacemaker_nodes'
    pacemaker_nodes_structure.keys
  end

  def pacemaker_nodes=(expected_nodes)
    debug "Call: pacemaker_nodes='#{expected_nodes.inspect}'"
    existing_nodes = pacemaker_nodes_structure.keys
    # remove unexpected existing nodes
    existing_nodes.each do |node|
      next if expected_nodes.include? node
      remove_pacemaker_node node
    end
  end

end
