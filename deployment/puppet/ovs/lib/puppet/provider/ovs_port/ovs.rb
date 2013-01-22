Puppet::Type.type(:ovs_port).provide(:ovs) do
  optional_commands :vsctl => "/usr/bin/ovs-vsctl"

  def exists?
    vsctl("list-ports", @resource[:bridge]).include? @resource[:interface]
  end

  def create
    begin
      vsctl('port-to-br', @resource[:interface])
      if @resource[:skip_existing]
        return true
      else
        raise ExecutionFailure, "Port '#{@resource[:interface]}' already exists."
      end
    rescue Puppet::ExecutionFailure
      # pass
    end
    cmd = [@resource[:bridge], @resource[:interface]]
    if @resource[:type] and @resource[:type].to_s != ''
      tt = "type=" + @resource[:type].to_s
      cmd += ['--', "set", "Interface", @resource[:interface], tt]
    end
    cmd = ["add-port"] + cmd
    vsctl(cmd)
  end

  def destroy
    vsctl("del-port", @resource[:bridge], @resource[:interface])
  end
end
