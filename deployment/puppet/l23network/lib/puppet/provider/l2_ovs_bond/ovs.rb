Puppet::Type.type(:l2_ovs_bond).provide(:ovs) do
  optional_commands(
    :vsctl  => "/usr/bin/ovs-vsctl",
    :appctl => "/usr/bin/ovs-appctl"
  )

  def _exists?(bond)
    begin
      appctl('bond/show', bond)
      true
    rescue Puppet::ExecutionFailure
      false
    end
  end

  def exists?
    _exists?(@resource[:bond])
  end

  def create
    if _exists?(@resource[:bond])
      msg = "Bond '#{@resource[:bond]}' already exists"
      if @resource[:skip_existing]
        notice("#{msg}, skip creating.")
      else
        fail("#{msg}.")
      end
    end

    bond_properties = Array(@resource[:properties])
    if @resource[:tag] > 0
      bond_properties.insert(-1, "tag=#{@resource[:tag]}")
    end
    if not @resource[:trunks].empty?
      bond_properties.insert(-1, "trunks=[#{@resource[:trunks].join(',')}]")
    end

    bond_create_cmd = ['add-bond', @resource[:bridge], @resource[:bond]] + @resource[:interfaces]
    if ! bond_properties.empty?
      bond_create_cmd += bond_properties
    end
    begin
      vsctl(bond_create_cmd)
    rescue Puppet::ExecutionFailure => error
      fail("Can't create bond '#{@resource[:bond]}' (interfaces: #{@resource[:interfaces].join(',')}) for bridge '#{@resource[:bridge]}'.\n#{error}")
    end
  end

  def destroy
    begin
      vsctl("del-port", @resource[:bridge], @resource[:bond])
    rescue Puppet::ExecutionFailure => error
      fail("Can't remove bond '#{@resource[:bond]}' from bridge '#{@resource[:bridge]}'.\n#{error}")
    end
  end

end
