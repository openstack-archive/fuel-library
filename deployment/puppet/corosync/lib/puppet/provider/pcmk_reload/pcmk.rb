Puppet::Type.type(:pcmk_reload).provide :pcmk do
  commands :crm_node => 'crm_node'
  commands :crm_mon => 'crm_mon'
  commands :ssh => 'ssh'

  RETRY_COUNT = 300
  RETRY_STEP = 6

  def pacemaker_is_running?
    begin
      crm_mon '-1'
      true
    rescue Puppet::ExecutionFailure
      false
    else
      true
    end
  end

  def crm_mon_data
    retry_command { crm_mon '-1' }.to_s
  end

  def hostname
    return @hostname if @hostname
    @hostname = retry_command { crm_node '-n' }.chomp.strip
  end

  def reload_node(node)
    return unless node
    debug "Try to restart corosync on '#{node}'"
    retry_command(3, 1, false) do
      ssh node, 'killall -9 corosync; /etc/init.d/corosync restart'
    end
  end

  def reload_self
    reload_node hostname
  end

  def nodes_status
    data = {}
    data[:nodes] = {}
    data[:dc] = nil
    crm_mon_data.split("\n").each do |line|
      if line.start_with? 'Current DC:'
        fields = line.split(/\s+/)
        data[:dc] = fields[2] if fields[2] and fields[2] != 'NONE'
      end
      if line.start_with? 'Online:'
        fields = line.split /\s+/
        fields.each do |node|
          next if %w(Online: [ ]).include? node
          data[:nodes].store node, :online
        end
      end
      if line.start_with? 'OFFLINE:'
        fields = line.split /\s+/
        fields.each do |node|
          next if %w(OFFLINE: [ ]).include? node
          data[:nodes].store node, :offline
        end
      end
    end
    debug "Status: #{data.inspect}"
    data
  end

  def retry_command(count = RETRY_COUNT, step = RETRY_STEP, fail = true)
    count.times do
      begin
        out = yield
      rescue Puppet::ExecutionFailure => e
        Puppet.debug "Command failed: #{e.message}"
        sleep step
      else
        return out
      end
    end
    fail "Execution timeout after #{count * step} seconds!" if fail
  end

  def retry_block_until_true(count = RETRY_COUNT, step = RETRY_STEP, fail = true)
    count.times do
      out = yield
      return out if out
      sleep step
    end
    fail "Execution timeout after #{count * step} seconds!" if fail
  end

  def my_status
    nodes_status[:nodes].fetch(hostname, :offline)
  end

  def reload_dc
    retry_block_until_true do
      nodes_status[:dc]
    end
    reload_node nodes_status[:dc]
  end

  def reload_all_nodes
    nodes_status[:nodes].each do |node, status|
      reload_node node if node
    end
  end

  def status
    debug "Call: status on #{@resource}"
    return :offline unless pacemaker_is_running?
    my_status
  end

  def status=(value)
    debug "Call: status='#{value}' on #{@resource}"
    return unless value == :online
    reload_self
    if @resource[:reload] == :all
      debug 'Reload corosync on all nodes'
      reload_all_nodes
    else
      debug 'Reload corosync on DC'
      reload_dc
    end
    retry_block_until_true do
      my_status == :online
    end
  end

end
