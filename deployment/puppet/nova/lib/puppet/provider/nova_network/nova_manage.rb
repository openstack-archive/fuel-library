Puppet::Type.type(:nova_network).provide(:nova_manage) do

  desc "Manage nova network"

  defaultfor :kernel => 'Linux'

  commands :nova_manage => 'nova-manage'

  def exists?
    begin
      nova_manage("network", "list").match(/^#{resource[:network]}\/[0-9]{1,2} /)
    rescue
      return false
    end
  end

  def create
     nova_manage("network", "create", resource[:label], resource[:network], "1", resource[:available_ips])
  end

  def destroy
    nova_manage("network", "delete", resource[:network])
  end

end

