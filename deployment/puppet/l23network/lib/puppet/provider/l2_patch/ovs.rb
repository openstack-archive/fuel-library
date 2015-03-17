require 'puppetx/l23_utils'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/ovs_base')

Puppet::Type.type(:l2_patch).provide(:ovs, :parent => Puppet::Provider::Ovs_base) do
  commands   :vsctl       => 'ovs-vsctl',
             :ethtool_cmd => 'ethtool',
             :brctl       => 'brctl',
             :iproute     => 'ip'


  def self.instances
    vsctl_show = ovs_vsctl_show()
    lnx_port_br_mapping = get_lnx_port_bridges_pairs()
    jacks = []
    # didn't use .select{...} here for backward compatibility with ruby 1.8
    vsctl_show[:port].reject{|k,v| !(v[:port_type] & ['jack','internal']).any?}.each_pair do |p_name, p_props|
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
        _bridges = [jack[:bridge], peer[:bridge]]  # no sort here!!! architecture limitation -- ovs brodge always first!
        _tails   = [jack[:name], jack[:name]]
        mtu      = File.open("/sys/class/net/#{jack[:name]}/mtu").read.chomp.to_i
      else
        # process patch between two OVS bridges
        next if jack[:peer].nil?
        found_peer = jacks.select{|j| j[:name]==jack[:peer]}
        next if found_peer.empty?
        peer = found_peer[0]
        _bridges = [jack[:bridge], peer[:bridge]].sort
        _tails   = ([jack[:bridge], peer[:bridge]] == _bridges  ?  [jack[:name], peer[:name]]  :  [peer[:name], jack[:name]])
      end
      props = {
        :ensure   => :present,
        :name     => L23network.get_patch_name([jack[:bridge],peer[:bridge]]),
        :bridges  => _bridges,
        :jacks    => _tails,
        :mtu      => mtu,
        :cross    => jack[:cross],
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
    @property_flush[:bridges] = bridges
    #
    debug("Bridges: '#{bridges.join(', ')}.")
    if File.directory?("/sys/class/net/#{bridges[1]}/bridge")
      # creating 'cross' OVS-to-lnx patchcord
      lnx_port_br_mapping = self.class.get_lnx_port_bridges_pairs()
      jack = L23network.get_lnx_jack_name(bridges[0])
      vsctl('--may-exist', 'add-port', bridges[0], jack, '--', 'set', 'Interface', jack, 'type=internal')
      if lnx_port_br_mapping.has_key? jack and lnx_port_br_mapping[jack][:bridge] != bridges[1]
        # eject lnx-side jack from bridge, if jack aldeady a member
        brctl('delif', lnx_port_br_mapping[jack][:bridge], jack)
        lnx_port_br_mapping.delete(jack)
      end
      if !lnx_port_br_mapping.has_key? jack
        begin
          brctl('addif', bridges[1], jack)
        rescue Exception => e
          if e.to_s =~ /device\s+#{jack}\s+is\s+already\s+a\s+member\s+of\s+a\s+bridge/
            notice("'#{jack}' already addeded to '#{bridges[1]}' by ghost event.")
          else
            raise
          end
        end
      end
    else
      # creating OVS-to-OVS patchcord
      jacks = []
      jacks << L23network.get_ovs_jack_name(bridges[1])
      jacks << L23network.get_ovs_jack_name(bridges[0])
      #todo(sv): make type and peer change in flush
      cmds = []
      cmds << ['--may-exist', 'add-port', bridges[0], jacks[0], '--', 'set', 'Interface', jacks[0], 'type=patch', "option:peer=#{jacks[1]}"]
      cmds << ['--may-exist', 'add-port', bridges[1], jacks[1], '--', 'set', 'Interface', jacks[1], 'type=patch', "option:peer=#{jacks[0]}"]
      cmds.each do |cmd|
        begin
          vsctl(cmd)
        rescue Puppet::ExecutionFailure => error
          raise Puppet::ExecutionFailure, "Can't add jack for patchcord '#{@resource[:name]}'\n#{error}"
        end
      end
    end
  end

  def destroy
    if File.directory?("/sys/class/net/#{@resource[:bridges][1]}/bridge")
      # removing 'cross' OVS-to-lnx patchcord
      jack = L23network.get_lnx_jack_name(@resource[:bridges][0])
      if File.symlink?("/sys/class/net/#{@resource[:bridges][1]}/brif/#{jack}")
        brctl('delif', @resource[:bridges][1], jack)
      end
      vsctl('del-port', @resource[:bridges][0], jack)
    else
      # removing OVS-to-OVS patchcord
      bridges = @resource[:bridges].sort
      jacks = []
      jacks << L23network.get_ovs_jack_name(bridges[1])
      jacks << L23network.get_ovs_jack_name(bridges[0])
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
      if !['', 'absent'].include? @property_flush[:mtu].to_s
        # 'absent' is a synonym 'do-not-touch' for MTU
        @resource[:jacks].uniq.each do |iface|
          self.class.set_mtu(iface, @property_flush[:mtu])
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