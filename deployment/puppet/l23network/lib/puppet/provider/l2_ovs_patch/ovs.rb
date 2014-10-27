Puppet::Type.type(:l2_ovs_patch).provide(:ovs) do
  optional_commands(
    :vsctl  => "/usr/bin/ovs-vsctl",
    :appctl => "/usr/bin/ovs-appctl"
  )

  def get_names()
    # result always contains array of two elements
    # get_names()[i-1] always returns neighbor's name
    #
    rv = []
    i = 0
    for peer in @resource[:peers]
      if peer == nil
        rv.insert(-1, "#{@resource[:bridges][i]}--#{@resource[:bridges][i-1]}")
      else
        rv.insert(-1, peer)
      end
      i += 1
    end
    #todo: check tags, trunks and bridge names
    return rv
  end

  def _exists?(interface)
    rv = true
    begin
      result = vsctl('get', 'interface', "#{interface}", 'type')
      rv =  false if result.strip() != 'patch'
    rescue Puppet::ExecutionFailure
      rv = false
    end
    return rv
  end

  def exists?
    for name in get_names()
      return false if not _exists?(name)
    end
    return true
  end

  def create()
    names = get_names()
    i = 0
    for name in names
      # tag and trunks for port
      port_properties = [] #@resource[:port_properties]
      tag = @resource[:tags][i]
      if tag > 0
        port_properties.insert(-1, "tag=#{tag}")
      end
      if not @resource[:trunks].empty?
        port_properties.insert(-1, "trunks=[#{@resource[:trunks].join(',')}]")
      end
      #todo: kill before create if need
      cmd = ['add-port', @resource[:bridges][i], name]
      cmd.concat(port_properties)
      cmd.concat(['--', 'set', 'interface', name, 'type=patch'])
      begin
        vsctl(cmd)
      rescue Puppet::ExecutionFailure => errmsg
        raise Puppet::ExecutionFailure, "Can't create patch '#{name}':\n#{errmsg}"
      end
      i += 1
    end
    i = 0
    for name in names
      begin
        vsctl('set', 'interface', name, "options:peer=#{names[i-1]}")
      rescue Puppet::ExecutionFailure => errmsg
        raise Puppet::ExecutionFailure, "Can't connect patch '#{name}' to '#{names[i-1]}':\n#{errmsg}"
      end
      i += 1
    end
  end

  def destroy()
    names = get_names()
    i = 0
    for name in names
      begin
        vsctl('del-port', @resource[:bridges][i], name)
      rescue Puppet::ExecutionFailure => error
        raise Puppet::ExecutionFailure, "Can't remove patch '#{name}' from bridge '#{@resource[:bridges][i]}':\n#{error}"
      end
      i += 1
    end
  end
end
