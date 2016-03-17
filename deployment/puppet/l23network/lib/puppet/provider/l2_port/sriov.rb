require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l2_port).provide(:sriov, :parent => Puppet::Provider::Lnx_base) do
  commands   :ethtool_cmd => 'ethtool',
             :pkill       => 'pkill'


  def self.instances
    rv = []
    ports = get_lnx_ports
    ports.each_pair do |if_name, if_props|
      debug("prefetching interface '#{if_name}'")

      props = {
        :ensure          => :present,
        :name            => if_name,
        :vendor_specific => {}
      }
      props.merge! if_props

      sriov_numvfs = self.get_sriov_numvfs(if_name)
      if sriov_numvfs and sriov_numvfs > 0
        props[:provider] = 'sriov'
        props[:vendor_specific] = {'sriov_numvfs' => sriov_numvfs.to_s}
      end

      props[:port_type] = props[:port_type].insert(0, props[:provider]).join(':')
      if props[:provider] == 'sriov'
        rv << new(props)
        debug("PREFETCH properties for '#{if_name}': #{props}")
      else
        debug("SKIP properties for '#{if_name}': #{props}")
      end
    end
    return rv
  end

  def self.sriov_numvfs_file(iface)
    "/sys/class/net/#{iface}/device/sriov_numvfs"
  end

  def self.get_sriov_numvfs(iface)
    File.read(self.sriov_numvfs_file(iface)).to_i if File.exists? self.sriov_numvfs_file(iface)
  end

  def sriov_numvfs
    self.class.get_sriov_numvfs(@resource[:interface])
  end

  def sriov_numvfs=(val)
    sriov_numvfs_file = self.class.sriov_numvfs_file(@resource[:interface])
    raise "'#{@resource[:interface]}' does not support sriov." unless File.exists? sriov_numvfs_file
    File.open(sriov_numvfs_file, "a") {|f| f << val}
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
    unless @property_flush.empty?
    debug("FLUSH properties: #{@property_flush}")
      unless ['', 'absent'].include? @property_flush[:mtu].to_s
        self.class.set_mtu(@resource[:interface], @property_flush[:mtu])
      end
      vendor_specific = (@property_flush[:vendor_specific] || {})
      unless vendor_specific["sriov_numvfs"].nil?
        self.sriov_numvfs = 0
        self.sriov_numvfs = vendor_specific["sriov_numvfs"].to_i
      end
      @property_hash = resource.to_hash
    end
  end

  def vendor_specific
    @property_hash[:vendor_specific] || :absent
  end
  def vendor_specific=(val)
    old = @property_hash[:vendor_specific] || {}
    changes = val.to_a - old.to_a
    @property_flush[:vendor_specific] = Hash[changes]
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
