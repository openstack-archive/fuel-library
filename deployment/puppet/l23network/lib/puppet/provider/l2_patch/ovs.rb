require 'puppetx/l23_utils'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/ovs_base')

Puppet::Type.type(:l2_patch).provide(:ovs, :parent => Puppet::Provider::Ovs_base) do
  commands   :vsctl       => 'ovs-vsctl',
             :ethtool_cmd => 'ethtool'

  def self.get_instances(big_hash)
    big_hash.fetch(:port, {})
  end

  def self.instances
    vsctl_show = ovs_vsctl_show()
    lnx_port_br_mapping = get_lnx_port_bridges_pairs()
    jacks = []
    # didn't use .select{...} here for backward compatibility with ruby 1.8
    vsctl_show.fetch(:port,{}).reject{|k,v| !(v[:port_type] & ['jack','internal']).any?}.each_pair do |p_name, p_props|
      props = {
        :name => p_name,
      }
      props.merge! p_props
      if props[:port_type].include? 'jack'
        debug("found jack '#{p_name}'")
        # get 'peer' property and copy to jack
        # didn't use .select{...} here for backward compatibility with ruby 1.8
        ifaces = vsctl_show[:interface].reject{|k,v| v[:port]!=p_name}
        iface = ifaces[ifaces.keys[0]]
        props[:peer] = (iface.has_key?(:options)  ?  iface[:options]['peer']  :  nil)
      elsif props[:port_type].include? 'internal'
        debug("found 'internal' ovs port '#{p_name}'")
        props[:cross] = true
      else
        #pass
      end
      jacks << props
    end
    # search pairs of jacks and make patchcord resources
    patches = []
    skip = []
    mtu = nil
    jacks.each do |jack|
      next if skip.include? jack[:name]
      if jack[:cross]
        # process 'cross' patch between OVS and LNX bridge
        peer = lnx_port_br_mapping[jack[:name]]
        next if peer.nil?
        _bridges  = [jack[:bridge], peer[:bridge]]  # no sort here!!! architecture limitation -- ovs brodge always first!
        _tails    = [jack[:name], jack[:name]]
        _vlan_ids = [(jack[:vlan_id].to_i or 0), 0]
        mtu       = File.open("/sys/class/net/#{jack[:name]}/mtu").read.chomp.to_i
      else
        # process patch between two OVS bridges
        next if jack[:peer].nil?
        found_peer = jacks.select{|j| j[:name]==jack[:peer]}
        next if found_peer.empty?
        peer = found_peer[0]
        _bridges  = [jack[:bridge], peer[:bridge]].sort
        _tails    = ([jack[:bridge], peer[:bridge]] == _bridges  ?  [jack[:name], peer[:name]]  :  [peer[:name], jack[:name]])
        _vlan_ids = [jack[:vlan_id].to_i, peer[:vlan_id].to_i]
      end
      props = {
        :ensure   => :present,
        :name     => L23network.get_patch_name([jack[:bridge],peer[:bridge]]),
        :bridges  => _bridges,
        :jacks    => _tails,
        :mtu      => mtu.to_s,
        :cross    => jack[:cross],
        :vlan_ids => _vlan_ids.map{|x| x.to_s},
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
    bridges = self.class.get_bridges_order_for_patch(@resource[:bridges])
    #
    debug("Bridges: '#{@resource[:bridges].join(', ')}'.")
    if File.directory?("/sys/class/net/#{bridges[1]}/bridge")
      # creating 'cross' OVS-to-lnx patchcord
      @property_flush[:bridges] = bridges
      @resource[:cross] = true
      lnx_port_br_mapping = self.class.get_lnx_port_bridges_pairs()
      jack = L23network.get_jack_name(bridges,0)
      @resource[:jacks] = [jack, jack]
      vsctl('--may-exist', 'add-port', bridges[0], jack, '--', 'set', 'Interface', jack, 'type=internal')
      if lnx_port_br_mapping.has_key? jack and lnx_port_br_mapping[jack][:bridge] != bridges[1]
        # eject lnx-side jack from bridge, if jack aldeady a member
        self.brctl(['delif', lnx_port_br_mapping[jack][:bridge], jack])
        lnx_port_br_mapping.delete(jack)
      end
      if !lnx_port_br_mapping.has_key? jack
        begin
          self.class.brctl(['addif', bridges[1], jack])
        rescue Exception => e
          if e.to_s =~ /device\s+#{jack}\s+is\s+already\s+a\s+member\s+of\s+a\s+bridge/
            notice("'#{jack}' already addeded to '#{bridges[1]}' by ghost event.")
          else
            raise
          end
        end
      end
      self.class.interface_up(jack)
    else
      # creating OVS-to-OVS patchcord
      bridges = @resource[:bridges]
      jacks = []
      jacks << L23network.get_jack_name(bridges,0)
      jacks << L23network.get_jack_name(bridges,1)
      #todo(sv): make type and peer change in flush
      cmds = []
      cmds << ['--may-exist', 'add-port', bridges[0], jacks[0], '--', 'set', 'Interface', jacks[0], 'type=patch', "option:peer=#{jacks[1]}"]
      cmds << ['--may-exist', 'add-port', bridges[1], jacks[1], '--', 'set', 'Interface', jacks[1], 'type=patch', "option:peer=#{jacks[0]}"]
debug(cmds)
      cmds.each do |cmd|
        begin
          vsctl(cmd)
        rescue Puppet::ExecutionFailure => error
          raise Puppet::ExecutionFailure, "Can't add jack for patchcord '#{@resource[:name]}'\n#{error}"
        end
      end
    end
    @property_hash = resource.to_hash
  end

  def destroy
    if File.directory?("/sys/class/net/#{@resource[:bridges][1]}/bridge")
      # removing 'cross' OVS-to-lnx patchcord
      jack = L23network.get_jack_name(@resource[:bridges], 0)
      # we don't normalize bridge ordering, because OVS bridge always first. by design.
      if File.symlink?("/sys/class/net/#{@resource[:bridges][1]}/brif/#{jack}")
        self.class.brctl(['delif', @resource[:bridges][1], jack])
      end
      vsctl('del-port', @resource[:bridges][0], jack)
    else
      # removing OVS-to-OVS patchcord
      bridges = L23network.get_normalized_bridges_order(@resource[:bridges])
      jacks = []
      jacks << L23network.get_jack_name(bridges,0)
      jacks << L23network.get_jack_name(bridges,1)
      cmds = []
      cmds << ['del-port', bridges[0], jacks[0]]
      cmds << ['del-port', bridges[1], jacks[1]]
      cmds.each do |cmd|
        begin
          vsctl(cmd)
        rescue Puppet::ExecutionFailure => error
          raise Puppet::ExecutionFailure, "Can't remove jack for patchcord '#{@resource[:name]}'\n#{error}"
        end
      end
    end
  end

  def flush
    if !@property_flush.empty?
      debug("FLUSH properties: #{@property_flush}")
#      debug("For resource #{@resource.to_yaml}")
      if !['', 'absent'].include? @property_flush[:mtu].to_s
        # 'absent' is a synonym 'do-not-touch' for MTU
        @property_hash[:jacks].uniq.each do |iface|
          self.class.set_mtu(iface, @property_flush[:mtu])
        end
      end
      if @property_flush.has_key? :vlan_ids
        debug("Operate cross-bridge patchcord.") if @property_hash[:cross]
        real_jack_count = @property_hash[:jacks].uniq.length
        (0..real_jack_count-1).each do |i|
          tag = @property_flush[:vlan_ids][i].to_i
          if tag != 0
            # set 802.1q tag to port
            vsctl('set', 'Port', @property_hash[:jacks][i], "tag=#{tag}")
          else
            # remove 802.1q tag from port
            vsctl('set', 'Port', @property_hash[:jacks][i], "tag=[]")
          end
        end
        if real_jack_count == 1 and @property_hash[:vlan_ids][1] != @property_flush[:vlan_ids][1]
          warn("You try to change vlan_id for LNX jack of cross-patch-cord, but it's impossible!")
        end
      end
      @property_hash = resource.to_hash
    end
  end

  #-----------------------------------------------------------------

  def bridges
    self.class.get_bridges_order_for_patch(@property_hash[:bridges])
  end
  def bridges=(val)
    @property_flush[:bridges] = self.class.get_bridges_order_for_patch(val)
  end

  def vlan_ids
    @property_hash[:vlan_ids]
  end
  def vlan_ids=(val)
    @property_flush[:vlan_ids] = val
  end

  def mtu
    'absent'
  end
  def mtu=(val)
    @property_flush[:mtu] = val
  end

  def jacks
    @property_hash[:jacks]
  end
  def jacks=(val)
    nil
  end

  def cross
    @property_hash[:cross]
  end
  def cross=(val)
    nil
  end

end
# vim: set ts=2 sw=2 et :
