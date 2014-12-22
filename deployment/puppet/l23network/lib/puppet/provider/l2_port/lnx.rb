Puppet::Type.type(:l2_port).provide(:lnx) do
  defaultfor :osfamily => :linux
  commands   :iproute => 'ip',
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
          props[:onboot] = false
        end

        # get MTU
        if File.open("/sys/class/net/#{if_name}/mtu", "r").each.select{|l| l.match(/^(\d+)$/)}.size > 0
          props[:mtu] = $1.to_s
        end
        debug("PREFETCHED properties for '#{if_name}': #{props}")
        new(props)
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    # todo: divide simple creating interface and vlan
    iproute('link', 'add', 'link', @resource[:vlan_dev], 'name', @resource[:interface], 'type', 'vlan', 'id', @resource[:vlan_id])
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
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

  def flush
    if @property_flush
      #options = []
      debug("FLUSH properties: #{@property_flush}")
      if ! @property_flush[:mtu].nil?
        File.open("/sys/class/net/#{@resource[:interface]}/mtu", "w") { |f| f.write(@property_flush[:mtu]) }
      end
      if ! @property_flush[:onboot].nil?
        iproute('link', 'set', 'dev', @resource[:interface], 'up')
      end
    end
  end

end