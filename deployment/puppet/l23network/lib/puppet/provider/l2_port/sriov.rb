require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l2_port).provide(:sriov, :parent => Puppet::Provider::Lnx_base) do
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
        :vendor_specific => {}
      }
      debug("prefetching interface '#{if_name}'")
      props.merge! if_props
      if_provider = props[:provider]
      props[:port_type] = props[:port_type].insert(0, if_provider).join(':')
      if if_provider == 'sriov'
        rv << new(props)
        debug("PREFETCH properties for '#{if_name}': #{props}")
      else
        debug("SKIP properties for '#{if_name}': #{props}")
      end
    end
    return rv
  end

  def sriov_numvfs_file
    "/sys/class/net/#{@resource[:interface]}/device/sriov_numvfs"
  end

  def sriov_numvfs
    val = nil
    if File.exists? self.sriov_numvfs_file
      File.open(sriov_numvfs_file, "r") {|x| val = x.read.to_i }
    end
    val
  end

  def sriov_numvfs=(val)
    if val >=0 and File.exists? self.sriov_numvfs_file
      File.open(self.sriov_numvfs_file, "a") {|f| f << val}
    else
      raise "'#{@resource[:interface]}' does not support sriov."
    end
  end

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    self.class.interface_up(@resource[:interface])
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    self.sriov_numvfs = 0
    self.class.interface_down(@resource[:interface], true)
  end

  def flush
    if ! @property_flush.empty?
      if !['', 'absent'].include? @property_flush[:mtu].to_s
        self.class.set_mtu(@resource[:interface], @property_flush[:mtu])
      end
      vs = (@property_flush[:vendor_specific] || {})
      sriov_numvfs = vs["sriov_numvfs"].to_i
      if self.sriov_numvfs != sriov_numvfs
        self.sriov_numvfs = 0
        self.sriov_numvfs = sriov_numvfs
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

  def vlan_dev
    @property_hash[:vlan_dev] || :absent
  end
  def vlan_dev=(val)
    @property_flush[:vlan_dev] = val
  end

  def vlan_id
    @property_hash[:vlan_id] || :absent
  end
  def vlan_id=(val)
    @property_flush[:vlan_id] = val
  end

  def vlan_mode
    @property_hash[:vlan_mode] || :absent
  end
  def vlan_mode=(val)
    @property_flush[:vlan_mode] = val
  end

  def bond_master
    @property_hash[:bond_master] || :absent
  end
  def bond_master=(val)
    @property_flush[:bond_master] = val
  end
end
# vim: set ts=2 sw=2 et :
