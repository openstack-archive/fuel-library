Puppet::Type.type(:l2_ovs_port).provide(:ovs) do
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
        raise Puppet::ExecutionFailure, "Port '#{@resource[:interface]}' already exists."
      end
    rescue Puppet::ExecutionFailure
      # pass
    end
    # tag and trunks for port
    port_properties = @resource[:port_properties]
    if @resource[:tag] > 0
      port_properties.insert(-1, "tag=#{@resource[:tag]}")
    end
    if not @resource[:trunks].empty?
      port_properties.insert(-1, "trunks=[#{@resource[:trunks].join(',')}]")
    end
    # Port create begins from definition brodge and port
    cmd = [@resource[:bridge], @resource[:interface]]
    # add port properties (k/w) to command line
    if not port_properties.empty?
      for option in port_properties
        cmd.insert(-1, option)
      end
    end
    # set interface type
    if @resource[:type] and @resource[:type].to_s != ''
      tt = "type=" + @resource[:type].to_s
      cmd += ['--', "set", "Interface", @resource[:interface], tt]
    end
    # executing OVS add-port command
    cmd = ["add-port"] + cmd
    begin
      vsctl(cmd)
    rescue Puppet::ExecutionFailure => error
      raise Puppet::ExecutionFailure, "Can't add port '#{@resource[:interface]}'\n#{error}"
    end
    # set interface properties
    if @resource[:interface_properties]
      for option in @resource[:interface_properties]
        begin
          vsctl('--', "set", "Interface", @resource[:interface], option.to_s)
        rescue Puppet::ExecutionFailure => error
          raise Puppet::ExecutionFailure, "Interface '#{@resource[:interface]}' can't set option '#{option}':\n#{error}"
        end
      end
    end
    # enable vlan_splinters if need
    if @resource[:vlan_splinters].to_s() == 'true'  # puppet send non-boolean value instead true/false
      Puppet.debug("Interface '#{@resource[:interface]}' vlan_splinters is '#{@resource[:vlan_splinters]}' [#{@resource[:vlan_splinters].class}]")
      begin
        vsctl('--', "set", "Port", @resource[:interface], "vlan_mode=trunk")
        vsctl('--', "set", "Interface", @resource[:interface], "other-config:enable-vlan-splinters=true")
      rescue Puppet::ExecutionFailure => error
        raise Puppet::ExecutionFailure, "Interface '#{@resource[:interface]}' can't setup vlan_splinters:\n#{error}"
      end
    end
  end

  def destroy
    vsctl("del-port", @resource[:bridge], @resource[:interface])
  end
end
