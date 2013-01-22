Puppet::Type.type(:ovs_port).provide(:ovs) do
  optionalcommands :vsctl => "/usr/bin/ovs-vsctl"

  def exists?
    vsctl("list-ports", @resource[:bridge]).include? @resource[:interface]
  end

  def create
    cmd = [@resource[:bridge], @resource[:interface]]
    if @resource[:type] and @resource[:type].to_s != ''
      tt = "type=" + @resource[:type].to_s
      cmd += ['--', "set", "Interface", @resource[:interface], tt]
    end
    cmd = ['--may-exist',] + cmd if @resource[:may_exist]
    cmd = ["add-port"] + cmd
    vsctl(cmd)
  end

  def destroy
    vsctl("del-port", @resource[:bridge], @resource[:interface])
  end
end
