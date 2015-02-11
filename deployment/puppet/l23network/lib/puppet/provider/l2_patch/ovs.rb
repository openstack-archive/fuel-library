require 'puppetx/l23_utils'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/ovs_base')

Puppet::Type.type(:l2_patch).provide(:ovs, :parent => Puppet::Provider::Ovs_base) do
  commands   :vsctl       => 'ovs-vsctl',
             :ethtool_cmd => 'ethtool',
             :iproute     => 'ip'


  def self.instances
    vsctl_show = ovs_vsctl_show()
    jacks = []
    vsctl_show[:port].select{|k,v| v[:provider]=='ovs' and v[:port_type].include? 'jack'}.each_pair do |p_name, p_props|
      debug("prefetching jack '#{p_name}'")
      props = {
        :name => p_name,
      }
      props.merge! p_props
      # get 'peer' property and copy to jack
      ifaces = vsctl_show[:interface].select{|k,v| v[:port]==p_name}
      iface = ifaces[ifaces.keys[0]]
      props[:peer] = (iface.has_key?(:options)  ?  iface[:options]['peer']  :  nil)
      jacks << props
    end
    # search pairs of jacks and make patchcord resources
    patches = []
    skip = []
    jacks.each do |jack|
      next if skip.include? jack[:name]
      found_peer = jacks.select{|j| j[:name]==jack[:peer]}
      next if found_peer.empty?
      peer = found_peer[0]
      props = {
        :ensure   => :present,
        :name     => L23network.get_patch_name([jack[:bridge],peer[:bridge]]),
        :bridges  => [jack[:bridge], peer[:bridge]].sort,
        :provider => 'ovs'
      }
      debug("PREFETCH properties for '#{props[:name]}': #{props}")
      patches << new(props)
      skip << peer[:name]
    end
    return patches #.map{|x| new(x)}
  end

  #-----------------------------------------------------------------

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    #
    cmd = ["add-port", @resource[:bridge], @resource[:interface]]
    # # tag and trunks for port
    # port_properties = @resource[:port_properties]
    # if ![nil, :absent].include? @resource[:vlan_id] and @resource[:vlan_id] > 0
    #   port_properties << "tag=#{@resource[:vlan_id]}"
    # end
    # if ![nil, :absent].include? @resource[:trunks] and !@resource[:trunks].empty?
    #   port_properties.insert(-1, "trunks=[#{@resource[:trunks].join(',')}]")
    # end
    # Port create begins from definition brodge and port
    # # add port properties (k/w) to command line
    # if not port_properties.empty?
    #   for option in port_properties
    #     cmd.insert(-1, option)
    #   end
    # end
    # set interface type
    if @resource[:type] and (@resource[:type].to_s != '' or @resource[:type].to_s != :absent)
      tt = "type=" + @resource[:type].to_s
    else
      tt = "type=internal"
    end
    cmd += ['--', "set", "Interface", @resource[:interface], tt]
    # executing OVS add-port command
    begin
      vsctl(cmd)
    rescue Puppet::ExecutionFailure => error
      raise Puppet::ExecutionFailure, "Can't add port '#{@resource[:interface]}'\n#{error}"
    end
    # # set interface properties
    # if @resource[:interface_properties]
    #   for option in @resource[:interface_properties]
    #     begin
    #       vsctl('--', "set", "Interface", @resource[:interface], option.to_s)
    #     rescue Puppet::ExecutionFailure => error
    #       raise Puppet::ExecutionFailure, "Interface '#{@resource[:interface]}' can't set option '#{option}':\n#{error}"
    #     end
    #   end
    # end
  end

  def destroy
    vsctl("del-port", @resource[:bridge], @resource[:interface])
  end

  def flush
    if @property_flush
      debug("FLUSH properties: #{@property_flush}")
      if @property_flush.has_key? :mtu
        if !@property_flush[:mtu].nil? and @property_flush[:mtu] != :absent
          #todo(sv): process array if interfaces
          iproute('link', 'set', 'mtu', @property_flush[:mtu].to_i, 'dev', @resource[:interface])
        else
          # remove MTU
          #todo(sv): process array if interfaces
          iproute('link', 'set', 'mtu', '1500', 'dev', @resource[:interface])
        end
      end
      if @property_flush.has_key? :vlan_id
        if !@property_flush[:vlan_id].nil? and @property_flush[:vlan_id] != :absent
          vsctl('set', 'Port', @resource[:interface], "tag=#{@property_flush[:vlan_id].to_i}")
        else
          # remove 802.1q tag
          vsctl('set', 'Port', @resource[:interface], "tag='[]'")
        end
      end
      @property_hash = resource.to_hash
    end
  end

  #-----------------------------------------------------------------

  def bridges
    @property_hash[:bridges] || nil
  end
  def bridges=(val)
    @property_flush[:bridges] = val
  end

  def vlan_ids
    @property_hash[:vlan_ids] || nil
  end
  def vlan_ids=(val)
    @property_flush[:vlan_ids] = val
  end

  def trunks
    @property_hash[:trunks] || nil
  end
  def trunks=(val)
    @property_flush[:trunks] = val
  end

end
# vim: set ts=2 sw=2 et :