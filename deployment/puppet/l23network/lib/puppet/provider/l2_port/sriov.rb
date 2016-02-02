require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

#todo: special type that couldn't be bonded or bridged
Puppet::Type.type(:l2_port).provide(:sriov, :parent => Puppet::Provider::Lnx_base) do
  defaultfor :kernel    => :linux
  commands   :ethtool_cmd => 'ethtool',
             :pkill       => 'pkill'


  def self.instances
    rv = []
    #todo: what do with OVS ports, inserted in LNX bridge? i.e. port located in two bridges.
    ports = get_lnx_ports()
    ports.each_pair do |if_name, if_props|
      props = {
        :ensure          => :present,
        :name            => if_name,
      }
      debug("prefetching interface '#{if_name}'")
      props.merge! if_props
      # add PROVIDER prefix to port type flags and convert port_type to string
      if_provider = props[:provider]
      props[:port_type] = props[:port_type].insert(0, if_provider).join(':')
    end
    return rv
  end

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    self.class.iproute(['link', 'set', 'dev', @resource[:interface], 'up'])
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    File.open("/sys/class/net/#{@resource[:interface]}/device/sriov_numvfs", "a") {|f| f << "0"}
    self.class.iproute(['link', 'set', 'dev', @resource[:interface], 'down'])
  end

  def flush
    if ! @property_flush.empty?
      debug("FLUSH properties: #{@property_flush}")
      if !['', 'absent'].include? @property_flush[:mtu].to_s
        self.class.set_mtu(@resource[:interface], @property_flush[:mtu])
      end
      vs = (@property_flush[:vendor_specific] || {})
      if vs.has_key? :sriov_numvfs
        File.open("/sys/class/net/#{@resource[:interface]}/device/sriov_numvfs", "a") {|f| f << "#{vs[:sriov_numvfs]}"}
      end
      @property_hash = resource.to_hash
    end
  end

  #-----------------------------------------------------------------
  def vendor_specific
    @property_hash[:vendor_specific] || :absent
  end
  def vendor_specific=(val)
    old = @property_hash[:vendor_specific] || {}
    # we're prefetching properties as hashes w/ keys as symbols, and set props as hashes w/ keys as strings
    # so here is normalization
    @property_flush[:vendor_specific] = Hash[val.map{|(k,v)| [k,v] if old[k.to_sym] != v }]
  end
end
# vim: set ts=2 sw=2 et :
