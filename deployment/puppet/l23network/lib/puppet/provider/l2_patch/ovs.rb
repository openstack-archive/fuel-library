require 'puppetx/l23_utils'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/ovs_base')

Puppet::Type.type(:l2_patch).provide(:ovs, :parent => Puppet::Provider::Ovs_base) do
  commands   :vsctl       => 'ovs-vsctl',
             :ethtool_cmd => 'ethtool',
             :brctl       => 'brctl',
             :iproute     => 'ip'


  def self.instances
    vsctl_show = ovs_vsctl_show()
    lnx_br_port_mapping = get_lnx_port_bridges_pairs()
    jacks = []
    vsctl_show[:port].select{|k,v| (v[:port_type] & ['jack','internal']).any?}.each_pair do |p_name, p_props|
      props = {
        :name => p_name,
      }
      props.merge! p_props
      if props[:port_type].include? 'jack'
        debug("found jack '#{p_name}'")
        # get 'peer' property and copy to jack
        ifaces = vsctl_show[:interface].select{|k,v| v[:port]==p_name}
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
    jacks.each do |jack|
      next if skip.include? jack[:name]
      if jack[:cross]
        # process 'cross' patch between OVS and LNX bridge
        peer = lnx_br_port_mapping[jack[:name]]
        next if peer.nil?
        _bridges = [jack[:bridge], peer[:bridge]]  # no sort here!!! architecture limitation -- ovs brodge always first!
        _tails   = [jack[:name], jack[:name]]
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
    #
    if File.directory?("/sys/class/net/#{@resource[:bridges][1]}/bridge")
      # creating 'cross' OVS-to-lnx patchcord
      bridges = @resource[:bridges]  # no sort here !!!
      jack = L23network.get_ovs_jack_name(bridges[0])
      vsctl('--may-exist', 'add-port', bridges[0], jack, '--', 'set', 'Interface', jack, 'type=internal')
      if !File.symlink?("/sys/class/net/#{@resource[:bridges][1]}/brif/#{jack}")
        brctl('addif', @resource[:bridges][1], jack)
      end
    else
      # creating OVS-to-OVS patchcord
      bridges = @resource[:bridges].sort
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
      # removinging 'cross' OVS-to-lnx patchcord
      bridges = @resource[:bridges]  # no sort here !!!
      jack = L23network.get_ovs_jack_name(bridges[0])
      if File.symlink?("/sys/class/net/#{@resource[:bridges][1]}/brif/#{jack}")
        brctl('delif', @resource[:bridges][1], jack)
      end
      vsctl('del-port', bridges[0], jack)
    else
      # creating OVS-to-OVS bridge
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
    if @property_flush
      debug("FLUSH properties: #{@property_flush}")
      # if @property_flush.has_key? :mtu
      #   if !@property_flush[:mtu].nil? and @property_flush[:mtu] != :absent
      #     #todo(sv): process array if interfaces
      #     iproute('link', 'set', 'mtu', @property_flush[:mtu].to_i, 'dev', @resource[:interface])
      #   else
      #     # remove MTU
      #     #todo(sv): process array if interfaces
      #     iproute('link', 'set', 'mtu', '1500', 'dev', @resource[:interface])
      #   end
      # end
      @property_hash = resource.to_hash
    end
  end

  #-----------------------------------------------------------------

  def bridges
    @property_hash[:bridges] || nil
  end
  def bridges=(val)
    @property_flush[:bridges] = val.sort
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