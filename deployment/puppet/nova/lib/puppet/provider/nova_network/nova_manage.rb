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

  def create
    optional_opts = []
    {
      # this needs to be converted from a project name to an id
      :project          => '--project_id',
      :dns2             => '--dns2',
      :gateway          => '--gateway',
      :bridge           => '--bridge',
      :vlan_start       => '--vlan_start'
    }.each do |param, opt|
      if resource[param]
        optional_opts.push(opt).push(resource[param])
      end
    end

    nova_manage('network', 'create',
      resource[:label],
      resource[:name],
      resource[:num_networks],
      resource[:network_size],
      optional_opts
    )
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


  def destroy
    nova_manage("network", "delete", resource[:network])
  end

end
