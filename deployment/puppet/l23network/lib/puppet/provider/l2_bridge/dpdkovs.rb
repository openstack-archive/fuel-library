Puppet::Type.type(:l2_bridge).provide(:dpdkovs, :parent => :ovs, :source => :ovs) do

  commands :vsctl => 'ovs-vsctl'

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource

    vendor_specific = @resource[:vendor_specific] || {}

    datapath_type = vendor_specific['datapath_type']
    cmd = ['add-br', @resource[:bridge]]
    cmd += ['--', 'set', 'Bridge', @resource[:bridge], "datapath_type=#{datapath_type}"] if datapath_type
    vsctl(cmd)

    # set vxlan id
    vlan_id = vendor_specific['vlan_id']
    vsctl('set', 'Port', @resource[:bridge], "tag=#{vlan_id}") if vlan_id

    self.class.interface_up(@resource[:bridge])
    notice("bridge '#{@resource[:bridge]}' created.")
  end

  def flush
    unless @property_flush.empty?
      super
      # handle vxlan id changes
      if @property_flush[:vendor_specific] && @property_flush[:vendor_specific] != :absent
        vlan_id = @property_flush[:vendor_specific]['vlan_id'] || []
        vsctl('set', 'Port', @resource[:bridge], "tag=#{vlan_id}")
      end
    end
  end

end
