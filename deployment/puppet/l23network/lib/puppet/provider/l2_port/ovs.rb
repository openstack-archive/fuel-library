require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/ovs_base')

Puppet::Type.type(:l2_port).provide(:ovs, :parent => Puppet::Provider::Ovs_base) do
#  confine    :osfamily => :linux
  commands   :vsctl   => 'ovs-vsctl',
             :iproute => 'ip'

  def self.instances
    rv = []
    #bridges ||= get_bridge_list()
    #todo: what do with OVS ports, inserted in LNX bridge? i.e. port located in two bridges.
    #ports = get_ovs_ports()
    ports = get_ovs_interfaces()
    ports.each_pair do |if_name, if_props|
      props = {
        :ensure          => :present,
        :name            => if_name,
        :vendor_specific => {}
      }
      debug("prefetching interface '#{if_name}'")
      props.merge! if_props
      ##add PROVIDER prefix to port type flags and convert port_type to string
      if_provider = props[:provider]
      props[:port_type] = props[:port_type].insert(0, if_provider).join(':')
      # if !bridges[if_name].nil?
      #   case bridges[if_name][:br_type]
      #   when :ovs
      #     props[:port_type] = 'ovs:br:unremovable'
      #   when :lnx
      #     props[:port_type] = 'lnx:br:unremovable'
      #   else
      #     # pass
      #   end
      # end
      debug("PREFETCHED properties for '#{if_name}': #{props}")
      rv << new(props) if if_provider == 'ovs'
    end
    return rv
  end

  def exists?
    @property_hash[:ensure] == :present
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
    if ![nil, :absent].include? @resource[:vlan_id] and @resource[:vlan_id] > 0
      port_properties << "tag=#{@resource[:vlan_id]}"
    end
    if ![nil, :absent].include? @resource[:trunks] and !@resource[:trunks].empty?
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

  def initialize(value={})
    super(value)
    @property_flush = {}
    @old_property_hash = {}
    @old_property_hash.merge! @property_hash
  end

  def flush
    if @property_flush
      debug("FLUSH properties: #{@property_flush}")
      #@property_hash = resource.to_hash
    end
  end

  #-----------------------------------------------------------------
  #-----------------------------------------------------------------
  def bridge
    @property_hash[:bridge] || :absent
  end
  def bridge=(val)
    @property_flush[:bridge] = val
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

  def port_type
    @property_hash[:port_type] || :absent
  end
  def port_type=(val)
    @property_flush[:port_type] = val
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

  def mtu
    @property_hash[:mtu] || :absent
  end
  def mtu=(val)
    @property_flush[:mtu] = val if val
  end

  def onboot
    @property_hash[:onboot] || :absent
  end
  def onboot=(val)
    @property_flush[:onboot] = val
  end

  def vendor_specific
    @property_hash[:vendor_specific] || {}
  end
  def vendor_specific=(val)
    @property_flush[:vendor_specific] = val
  end

  #-----------------------------------------------------------------


end
# vim: set ts=2 sw=2 et :