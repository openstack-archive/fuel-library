Puppet::Type.type(:l2_nsx_bridge).provide(
  :ovs,
  :parent => Puppet::Type.type(:l2_ovs_bridge).provider(:ovs)
) do
  optional_commands :vsctl => "/usr/bin/ovs-vsctl"

  def create
    super()
    self.in_band=(@resource[:in_band]) if @resource[:in_band]
    self.fail_mode=(@resource[:fail_mode]) if @resource[:fail_mode]
  end

  def in_band
    other_config = vsctl("get", "Bridge", @resource[:bridge], "other_config")
    if other_config.include? "disable-in-band"
      return vsctl("get", "Bridge", @resource[:bridge], "other_config:disable-in-band").tr('"','').strip
    end
    ''
  end

  def in_band=(value)
    vsctl("set", "Bridge", @resource[:bridge], "other_config:disable-in-band=#{value}")
  end

  def fail_mode
    vsctl("get", "Bridge", @resource[:bridge], "fail-mode").strip
  end

  def fail_mode=(value)
    vsctl("set", "Bridge", @resource[:bridge], "fail-mode=#{value}")
  end
end
