require 'puppetx/l23_utils'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/ovs_base')

Puppet::Type.type(:l2_patch).provide(:ovs2lnx, :parent => Puppet::Provider::Ovs_base) do
  commands   :vsctl       => 'ovs-vsctl',
             :ethtool_cmd => 'ethtool',
             :brctl       => 'brctl',
             :iproute     => 'ip'


  def self.instances
    debug("Getting native linux port-to-bridge mappings.")
    lnx_br_port_mapping = get_lnx_port_bridges_pairs()
    debug("mappings: '#{lnx_br_port_mapping}'")
    return [] if lnx_br_port_mapping.empty?
    debug("Getting OVS  port-to-bridge mappings.")
    vsctl_show = ovs_vsctl_show()
    jacks = []
    vsctl_show[:interface].select{|k,v| v[:port_type].include? 'internal'}.each_pair do |i_name, i_props|
      debug("'internal' ovs port '#{i_name}'")
      jacks << {
        :name   => i_props[:port],
        :bridge => vsctl_show[:port][i_props[:port]][:bridge]
      }
    end
    # search pairs of jacks and make patchcord resources
    patches = []
    skip = []
    jacks.each do |jack|
      peer = lnx_br_port_mapping[jack[:name]]
      next if peer.nil?
      props = {
        :ensure   => :present,
        :name     => L23network.get_patch_name([jack[:bridge],peer[:bridge]]),  # name has sorted bridge list -- it's a common rule for all 'patch' resources
        :bridges  => [jack[:bridge], peer[:bridge]],  # no sort here!!! architecture limitation -- ovs brodge always first!
        :jacks    => [jack[:name],jack[:name]],
        :provider => 'ovs2lnx'
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
    bridges = @resource[:bridges].sort
    jacks = []
    jacks << L23network.get_ovs_jack_name(bridges[1])
    jacks << L23network.get_ovs_jack_name(bridges[0])
    #todo(sv): make type and peer change in flush
    cmds = []
    cmds << ['--may-exist', 'add-port', bridges[0], jacks[0], '--', 'set', 'Interface', jacks[0], 'type=path', "option:peer=#{jacks[1]}"]
    cmds << ['--may-exist', 'add-port', bridges[1], jacks[1], '--', 'set', 'Interface', jacks[1], 'type=path', "option:peer=#{jacks[0]}"]
    cmds.each do |cmd|
      begin
        vsctl(cmd)
      rescue Puppet::ExecutionFailure => error
        raise Puppet::ExecutionFailure, "Can't add jack for patchcord '#{@resource[:name]}'\n#{error}"
      end
    end
  end

  def destroy
    bridges = @resource[:bridges].sort
    jacks = []
    jacks << L23network.get_ovs_jack_name(bridges[0])
    jacks << L23network.get_ovs_jack_name(bridges[1])
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