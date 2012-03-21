Puppet::Type.type(:nova_network).provide(:nova_manage) do

  desc "Manage nova network"

  optional_commands :nova_manage => 'nova-manage'

  def exists?
    begin
      network_list = nova_manage("network", "list")
      return network_list.split("\n")[1..-1].detect do |n|
        n =~ /^(\S+)\s+(#{resource[:network]})/
      end
    rescue
      return false
    end
  end

  def create
     nova_manage("network", "create", resource[:label], resource[:network], "1", resource[:available_ips], "--bridge=br100")
  end

  def destroy
    nova_manage("network", "delete", resource[:network])
  end

end

