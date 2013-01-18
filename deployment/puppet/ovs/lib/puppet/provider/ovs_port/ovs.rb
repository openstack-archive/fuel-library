Puppet::Type.type(:ovs_port).provide(:ovs) do
  commands :vsctl => "/usr/bin/ovs-vsctl"

  def exists?
    vsctl("list-ports", @resource[:bridge]).include? @resource[:interface]
  end

  def create
    if @resource[:type] and @resource[:type].to_s != ''
      tt = "type=" + @resource[:type].to_s
      vsctl("add-port", @resource[:bridge], @resource[:interface], '--', "set", "Interface", @resource[:interface], tt)
    else
      vsctl("add-port", @resource[:bridge], @resource[:interface])
    end
  end

  def destroy
    vsctl("del-port", @resource[:bridge], @resource[:interface])
  end
end
