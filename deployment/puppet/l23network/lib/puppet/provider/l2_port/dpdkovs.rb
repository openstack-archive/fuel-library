require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/ovs_base')

Puppet::Type.type(:l2_port).provide(:dpdkovs, :parent => Puppet::Provider::Ovs_base) do
  commands   :vsctl       => 'ovs-vsctl',
             :ethtool_cmd => 'ethtool'

  def self.add_unremovable_flag(port_props)
    # calculate 'unremovable' flag. Should be re-defined in chield providers
    if port_props[:port_type].include? 'bridge' or port_props[:port_type].include? 'bond'
      port_props[:port_type] << 'unremovable'
    end
  end

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
      debug("prefetching DPDK '#{p_name}'")
      props.merge! p_props
      props.merge! port_bridges[dpdk_name] if port_bridges.has_key? dpdk_name
      #next if skip_port_for? props
      #add_unremovable_flag(props)
      ##add PROVIDER prefix to port type flags and create puppet resource
      if props[:provider] == 'dpdkovs'
        props[:port_type] = props[:port_type].insert(0, 'dpdkovs').join(':')
        rv << new(props)
        debug("PREFETCH DPDK properties for '#{p_name}': #{props}")
      else
        debug("SKIP DPDK properties for '#{p_name}': #{props}")
      end
    end
    return rv
  end

  #-----------------------------------------------------------------

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
  end

  def destroy
    vsctl("del-port", @resource[:bridge], @resource[:interface])
  end

  def flush
    if ! @property_flush.empty?
      debug("FLUSH properties: #{@property_flush}")
      @property_hash = resource.to_hash
    end
  end

  #-----------------------------------------------------------------

  def ethtool
    @property_hash[:ethtool] || nil
  end
  def ethtool=(val)
    @property_flush[:ethtool] = val
  end

end
# vim: set ts=2 sw=2 et :