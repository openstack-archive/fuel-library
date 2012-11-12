require "puppet"

Puppet::Type.type(:vs_port).provide(:ovs) do
  commands :vsctl => "/usr/bin/ovs-vsctl"

  def exists?
    vsctl("list-ports", @resource[:bridge]).include? @resource[:interface]
  end

  def create
    vsctl("add-port", @resource[:bridge], @resource[:interface])
  end

  def destroy
    vsctl("del-port", @resource[:bridge], @resource[:interface])
  end
end
