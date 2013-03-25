Puppet::Type.type(:l2_ovs_bond).provide(:ovs) do
  optional_commands(
    :vsctl  => "/usr/bin/ovs-vsctl",
    :appctl => "/usr/bin/ovs-appctl"
  )

  def _exists(bond)
    begin
      appctl('bond/show', bond)
      return true
    rescue Puppet::ExecutionFailure
      return false
    end
  end

  def exists?
    _exists(@resource[:bond])
  end

  def create
    if _exists(@resource[:bond])
      msg = "Bond '#{@resource[:bond]}' already exists"
      if @resource[:skip_existing]
        notice("#{msg}, skip creating.")
      else
        fail("#{msg}.")
      end
    end

    bond_create_cmd = ['add-bond', @resource[:bridge], @resource[:bond]] + @resource[:ports]
    if ! @resource[:options].empty?
      bond_create_cmd += @resource[:options]
    end
    begin
      vsctl(bond_create_cmd)
    rescue Puppet::ExecutionFailure => error
      notice(">>>#{bond_create_cmd.join(',')}<<<")
      fail("Can't create bond '#{@resource[:bond]}' (ports: #{@resource[:ports].join(',')}) for bridge '#{@resource[:bridge]}'.\n#{error}")
    end
  end

  def destroy
    begin
      vsctl("del-port", @resource[:bridge], @resource[:bond])
    rescue Puppet::ExecutionFailure
      fail("Can't remove bond '#{@resource[:bond]}' from bridge '#{@resource[:bridge]}'.")
    end
  end

end
