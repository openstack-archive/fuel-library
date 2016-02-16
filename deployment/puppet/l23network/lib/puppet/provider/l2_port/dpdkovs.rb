require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/ovs_base')

Puppet::Type.type(:l2_port).provide(:dpdkovs, :parent => Puppet::Provider::Ovs_base) do
  commands   :vsctl       => 'ovs-vsctl',
             :ethtool_cmd => 'ethtool'

  def self.instances
    rv = []
    ports = get_dpdk_ports_mapping()
    port_bridges = get_port_bridges_pairs()
    ports.each_pair do |dpdk_name, p_props|
      p_name = p_props[:name].to_s
      props = {
        :ensure          => :present,
        :name            => p_name,
      }
      debug("prefetching '#{p_name}'")
      props.merge! p_props
      props.merge! port_bridges[dpdk_name] if port_bridges.has_key? dpdk_name
      if props[:provider] == 'dpdkovs'
        props[:port_type] = props[:port_type].insert(0, 'dpdkovs').join(':')
        rv << new(props)
        debug("PREFETCH properties for '#{p_name}': #{props}")
      else
        debug("SKIP properties for '#{p_name}': #{props}")
      end
    end
    return rv
  end

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    @resource[:type] = 'dpdk'

    ports = self.class.get_dpdk_ports_mapping()
    dpdk_interface = ports.map { |i,p| i if p[:name].to_s == @resource[:interface]}.compact[0]

    cmd = ['--may-exist', 'add-port', @resource[:bridge], dpdk_interface]
    tt = "type=" + @resource[:type].to_s
    cmd += ['--', "set", "Interface", dpdk_interface, tt] if tt

    begin
      vsctl(cmd)
    rescue Puppet::ExecutionFailure => error
      raise Puppet::ExecutionFailure, "Can't add port '#{@resource[:interface]}'\n#{error}"
    end
  end

  def destroy
    vsctl("del-port", @resource[:bridge], @resource[:interface])
    bus_info = @resource[:vendor_specific][:bus_info]
  end

  def flush
    if ! @property_flush.empty?
      debug("FLUSH properties: #{@property_flush}")
      @property_hash = resource.to_hash
    end
  end
end
# vim: set ts=2 sw=2 et :