Puppet::Type.type(:nova_network).provide(:nova_manage) do

  desc "Manage nova network"

  optional_commands :nova_manage => 'nova-manage'

  # I need to setup caching and what-not to make this lookup performance not suck
  def self.instances
    begin
      network_list = nova_manage("network", "list")
    rescue Exception => e
      if e.message =~ /No networks defined/
        return []
      else
        raise(e)
      end
    end
    network_list.split("\n")[1..-1].collect do |net|
      if net =~ /^(\S+)\s+(\S+)/
        new(:name => $2 )
      end
    end.compact
  end

  def exists?
    begin
      network_list = nova_manage("network", "list")
      return network_list.split("\n")[1..-1].detect do |n|
        # TODO - this does not take the CIDR into accont. Does it matter?
        n =~ /^(\S+)\s+(#{resource[:network].split('/').first})/
      end
    rescue
      return false
    end
  end

  def create
     mask=resource[:network].sub(/.*\/([1-3][0-9]?)/, '\1')
     available_ips=2**(32-mask.to_i)
     nova_manage("network", "create", resource[:label], resource[:network], "1", available_ips, "--bridge=#{resource[:bridge]}")
  end

  def destroy
    nova_manage("network", "delete", resource[:network])
  end

end

