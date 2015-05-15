require File.join File.dirname(__FILE__), '../pacemaker_common.rb'

Puppet::Type.type(:pcmk_nodes).provide(:ruby, :parent => Puppet::Provider::Pacemaker_common) do

  commands 'cmapctl'  => '/usr/sbin/corosync-cmapctl'
  commands 'cibadmin' => '/usr/sbin/cibadmin'
  commands 'crm_node' => '/usr/sbin/crm_node'
  commands 'crm_attribute' => '/usr/sbin/crm_attribute'

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
    begin
      cmapctl *args
    rescue => e
      info "Command failed: #{e.message}"
    end
  end

  def cibadmin_safe(*args)
    if @resource[:debug]
      debug (['cibadmin'] + args).join ' '
      return
    end
    begin
      cibadmin *args
    rescue => e
      info "Command failed: #{e.message}"
    end
  end

  def crm_node_safe(*args)
    if @resource[:debug]
      debug (['crm_node'] + args).join ' '
      return
    end
    begin
      crm_node *args
    rescue => e
      info "Command failed: #{e.message}"
    end
  end

  ###################################

  def nodes_data
    @resource[:nodes]
  end

  def corosync_nodes_data
    @resource[:corosync_nodes]
  end

  def pacemaker_nodes_data
    @resource[:pacemaker_nodes]
  end

  ###################################

  def corosync_nodes_state
    return @corosync_nodes_data if @corosync_nodes_data
    @corosync_nodes_data = {}
    cmapctl_nodelist.split("\n").each do |line|
      if line =~ %r(^nodelist\.node\.(\d+)\.nodeid\s+\(u32\)\s+=\s+(\d+))
        node_number = $1
        node_id = $2
        @corosync_nodes_data[node_number] = {} unless @corosync_nodes_data[node_number]
        @corosync_nodes_data[node_number]['id'] = node_id
        @corosync_nodes_data[node_number]['number'] = node_number
      end
      if line =~ %r(^nodelist\.node\.(\d+)\.ring(\d+)_addr\s+\(str\)\s+=\s+(\S+))
        node_number = $1
        node_ip_addr = $3
        @corosync_nodes_data[node_number] = {} unless @corosync_nodes_data[node_number]
        @corosync_nodes_data[node_number]['ip'] = node_ip_addr
      end
    end
    @corosync_nodes_data
  end

  def corosync_nodes_structure
    return @corosync_nodes_structure if @corosync_nodes_structure
    @corosync_nodes_structure = {}
    corosync_nodes_state.each do |number, node|
      id = node['id']
      ip = node['ip']
      next unless id and ip
      @corosync_nodes_structure.store id, ip
    end
    @corosync_nodes_structure
  end

  def pcmk_nodes_reset
    @corosync_nodes_structure = nil
    @corosync_nodes_data = nil
    @pacemaker_nodes_structure = nil
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
    @resource.set_corosync_nodes
    @resource.set_pacemaker_nodes
    pcmk_nodes_reset
  end

  ###

  def pacemaker_nodes_structure
    @pacemaker_nodes_structure = {}
    node_ids.each do |name, node|
      id = node['id']
      next unless name and id
      @pacemaker_nodes_structure.store name, id
    end
    @pacemaker_nodes_structure
  end

  def next_corosync_node_number
    number = corosync_nodes_state.inject(0) do |max, node|
      number = node.last['number'].to_i
      max = number if number > max
      max
    end
    number += 1
    number.to_s
  end

  def remove_pacemaker_node(node_name)
    debug "Remove pacemaker node: '#{node_name}'"
    remove_pacemaker_crm_node node_name
    remove_pacemaker_node_record node_name
    remove_pacemaker_node_state node_name
    purge_node_locations node_name
  end

  def add_pacemaker_node(node_name)
    debug "Add pacemaker node: '#{node_name}'"
    node_id = nodes_data.fetch(node_name, {}).fetch 'id', nil
    fail "Could not get all the data for the new pacemaker node '#{node_name}'!" unless node_id
    add_pacemaker_node_record node_name, node_id
    add_pacemaker_node_state node_name, node_id
  end

  def remove_pacemaker_crm_node(node_name)
    crm_node_safe '--force', '--remove', node_name
  end

  def remove_pacemaker_node_record(node_name)
    cibadmin_safe '--delete', '--scope', 'nodes', '--xml-text', "<node uname='#{node_name}'/>"
  end

  def remove_pacemaker_node_state(node_name)
    cibadmin_safe '--delete', '--scope', 'status', '--xml-text', "<node_state uname='#{node_name}'/>"
  end

  def remove_location_constraint(constraint_id)
    cibadmin_safe '--delete', '--scope', 'constraints', '--xml-text',  "<rsc_location id='#{constraint_id}'/>"
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

  def remove_corosync_node(node_id)
    debug "Remove corosync node: '#{node_id}'"
    node_number = nil
    corosync_nodes_state.each do |number, node|
      node_number = number if node['id'] == node_id
    end
    fail "Could not get node_number of node id: '#{node_id}'!" unless node_number
    remove_corosync_node_record node_number
    pcmk_nodes_reset
  end

  def remove_corosync_node_record(node_number)
    begin
      cmapctl_safe '-D', "nodelist.node.#{node_number}"
    rescue => e
      debug "Failed: #{e.message}"
    end
  end

  def add_corosync_node(node_id)
    debug "Add corosync node: '#{node_id}'"
    node_ip = corosync_nodes_data.fetch node_id, nil
    node_number = next_corosync_node_number
    fail "Could not get all the data for the new corosync node '#{node_name}'!" unless node_id and node_ip and node_number
    add_corosync_node_record node_number, node_ip, node_id
    pcmk_nodes_reset
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
    wait_for_online
    change_fqdn_to_name if change_fqdn_to_name?
    debug "Return: #{corosync_nodes_structure.inspect}"
    corosync_nodes_structure
  end

  def corosync_nodes=(expected_nodes)
    debug "Call: corosync_nodes='#{expected_nodes.inspect}'"
    existing_nodes = corosync_nodes_structure

    if @resource[:remove_corosync_nodes]
      existing_nodes.each do |existing_node_id, existing_node_ip|
        next if expected_nodes[existing_node_id] == existing_node_ip
        remove_corosync_node existing_node_id
      end
    end

    if @resource[:add_corosync_nodes]
      expected_nodes.each do |expected_node_id, expected_node_ip|
        next if existing_nodes[expected_node_id] == expected_node_ip
        add_corosync_node expected_node_id
      end
    end
  end

  def pacemaker_nodes
    debug 'Call: pacemaker_nodes'
    wait_for_online
    change_fqdn_to_name if change_fqdn_to_name?
    debug "Return: #{pacemaker_nodes_structure.inspect}"
    pacemaker_nodes_structure
  end

  def pacemaker_nodes=(expected_nodes)
    debug "Call: pacemaker_nodes='#{expected_nodes.inspect}'"
    existing_nodes = pacemaker_nodes_structure

    if @resource[:remove_pacemaker_nodes]
      existing_nodes.each do |existing_node_name, existing_node_id|
        next if expected_nodes[existing_node_name] == existing_node_id
        remove_pacemaker_node existing_node_name
      end
    end

    if @resource[:add_pacemaker_nodes]
      expected_nodes.each do |expected_node_name, expected_node_id|
        next if existing_nodes[expected_node_name] == expected_node_id
        add_pacemaker_node expected_node_name
      end
    end
  end

end
