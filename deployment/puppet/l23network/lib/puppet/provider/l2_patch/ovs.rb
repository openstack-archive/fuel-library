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