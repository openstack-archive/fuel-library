Puppet::Type.type(:l2_port).provide(:lnx) do
  defaultfor :osfamily => :linux
  commands   :iproute => 'ip',
             :brctl   => 'brctl',
             :vsctl   => 'ovs-vsctl'


  def self.prefetch(resources)
    interfaces = instances
    resources.keys.each do |name|
      if provider = interfaces.find{ |ii| ii.name == name }
        resources[name].provider = provider
      end
    end
  end

  def self.instances
    # get port-bridges mapping
    #todo: what do with OVS ports, inserted in LNX bridge? i.e. port located in two bridges.
    port_bridges_hash = self.get_lnx_port_bridges_pairs()
    #debug("port-bridges: '#{port_bridges_hash}'")
    port_bridges_hash.merge! self.get_ovs_port_bridges_pairs()
    debug("port-bridges mapping: '#{port_bridges_hash}'")
    # parse 802.1q vlan interfaces
    vlan_ifaces = {}
    rc_c = /([\w+\.\-]+)\s*\|\s*(\d+)\s*\|\s*([\w+\-]+)/
    File.open("/proc/net/vlan/config", "r").each do |line|
      if (rv=line.match(rc_c))
        vlan_ifaces[rv[1]] = {
          :vlan_dev  => rv[3],
          :vlan_id   => rv[2],
          :vlan_mode => (rv[1].match('\.').nil?  ?  'vlan'  :  'eth'  )
        }
      end
    end
    # parse all system interfaces
    re_c = /^\s*([0-9A-Za-z\.\-\_]+):/
    File.open("/proc/net/dev", "r").each.select{|line| line.match(re_c)}.collect do |if_line|
        mm = if_line.match(re_c)
        if_name = mm[1]
        props = {
          :ensure     => :present,
          :name       => if_name,
        }
        debug("prefetching interface '#{if_name}'")
        # check, whether this interface is vlan
        if File.file?("/proc/net/vlan/#{if_name}")
          props.merge!(vlan_ifaces[if_name])
        else
          props.merge!({
            :vlan_dev  => nil,
            :vlan_id   => nil,
            :vlan_mode => nil
          })
        end
        # check whether interface UP
        begin
          File.open("/sys/class/net/#{if_name}/carrier", "r").each.select{|l| l.match(/^(\d+)$/)}.size
          props[:onboot] = true
        rescue
          # if interface if down, this file can't be read
          props[:onboot] = false
        end

        # get MTU
        if File.open("/sys/class/net/#{if_name}/mtu", "r").each.select{|l| l.match(/^(\d+)$/)}.size > 0
          props[:mtu] = $1.to_s
        end
        # get bridge if port included to it
        if ! port_bridges_hash[if_name].nil?
          props[:bridge] = port_bridges_hash[if_name][:bridge]
        end
        debug("PREFETCHED properties for '#{if_name}': #{props}")
        new(props)
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    # todo: divide simple creating interface and vlan
    iproute('link', 'add', 'link', @resource[:vlan_dev], 'name', @resource[:interface], 'type', 'vlan', 'id', @resource[:vlan_id])
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    # todo: Destroing of L2 resource -- is a putting interface to the DOWN state.
    #       Or remove, if ove a vlan interface
    #iproute('--force', 'addr', 'flush', 'dev', @resource[:interface])
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
      #
      # FLUSH changed properties
      if ! @property_flush[:mtu].nil?
        File.open("/sys/class/net/#{@resource[:interface]}/mtu", "w") { |f| f.write(@property_flush[:mtu]) }
      end
      if ! @property_flush[:onboot].nil?
        iproute('link', 'set', 'dev', @resource[:interface], 'up')
      end
      if ! @property_flush[:bridge].nil?
        # get actual bridge-list. We should do it here,
        # because bridge may be not existing at prefetch stage.
        @bridges ||= self.class.get_bridge_list  # resource port can't change bridge list
        debug("Actual-bridge-list: #{@bridges}")
        port_bridges_hash = self.class.get_ovs_port_bridges_pairs()       # LNX bridges should overwrite OVS
        port_bridges_hash.merge! self.class.get_lnx_port_bridges_pairs()  # because if port includes in two bridges
        debug("Actual-port-bridge-mapping: '#{port_bridges_hash}'")       # it should removed from LNX
        #
        iproute('--force', 'link', 'set', 'dev', @resource[:interface], 'down')
        # remove interface from old bridge
        if ! port_bridges_hash[@resource[:interface]].nil?
          br_name = port_bridges_hash[@resource[:interface]][:bridge]
          br_type = port_bridges_hash[@resource[:interface]][:br_type]
          case br_type
          when :ovs
            vsctl('del-port', br_name, @resource[:interface])
          when :lnx
            brctl('delif', br_name, @resource[:interface])
          else
            #pass
          end
        end
        # add port to the new bridge
        if @property_flush[:bridge].to_sym != :absent
          case @bridges[@property_flush[:bridge]][:br_type]
          when :ovs
            vsctl('add-port', @property_flush[:bridge], @resource[:interface])
          when :lnx
            brctl('addif', @property_flush[:bridge], @resource[:interface])
          else
            #pass
          end
        end
        iproute('link', 'set', 'dev', @resource[:interface], 'up') if @resource[:onboot]
        debug("Change bridge")
      end
      @property_hash = resource.to_hash
    end
  end

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

  def mtu
    @property_hash[:mtu] || :absent
  end
  def mtu=(val)
    @property_flush[:mtu] = val
  end

  def onboot
    @property_hash[:onboot] || :absent
  end
  def onboot=(val)
    @property_flush[:onboot] = val
  end

  #-----------------------------------------------------------------
  def self.get_bridge_list
    bridges = {}
    # obtain OVS bridges list
    re_c = /^\s*([\w\-]+)/
    vsctl('list-br').split(/\n+/).select{|l| l.match(re_c)}.collect{|a| $1 if a.match(re_c)}.each do |br_name|
      br_name.strip!
      bridges[br_name] = {
        :br_type => :ovs
      }
    end
    # obtain LNX bridges list
    re_c = /([\w\-]+)\s+\d+/
    brctl('show').split(/\n+/).select{|l| l.match(re_c)}.collect{|a| $1 if a.match(re_c)}.each do |br_name|
      br_name.strip!
      bridges[br_name] = {
        :br_type => :lnx
      }
    end
    return bridges
  end

  def self.get_ovs_port_bridges_pairs
    portlist = {}
    ovs_bridges = vsctl('list-br').split(/\n+/).select{|l| l.match(/^\s*[\w\-]+/)}
    #todo: handle error
    ovs_bridges.each do |br_name|
      br_name.strip!
      ovs_portlist = vsctl('list-ports', br_name).split(/\n+/).select{|l| l.match(/^\s*[\w\-]+\s*/)}
      #todo: handle error
      ovs_portlist.each do |port_name|
        port_name.strip!
        portlist[port_name] = {
          :bridge  => br_name,
          :br_type => :ovs
        }
      end
      # bridge also a port, but it don't show itself by list-ports
      portlist[br_name] = {
        :bridge  => br_name,
        :br_type => :ovs
      }
    end
    return portlist
  end

  def self.get_lnx_port_bridges_pairs
    portlist = {}
    brctl_show = brctl('show').split(/\n+/).select{|l| l.match(/^[\w\-]+\s+\d+/) or l.match(/^\s+[\w\.\-]+/)}
    #todo: handle error
    br_name = nil
    brctl_show.each do |line|
      line.rstrip!
      case line
      when /^([\w\-]+)\s+[\d\.abcdef]+\s+(yes|no)\s+([\w\-\.]+$)/i
        br_name = $1
        port_name = $3
      when /^\s+([\w\.\-]+)$/
        #br_name using from previous turn
        port_name = $1
      else
        next
      end
      if br_name
        portlist[port_name] = {
          :bridge  => br_name,
          :br_type => :lnx
        }
      end
    end
    return portlist
  end

end
# vim: set ts=2 sw=2 et :