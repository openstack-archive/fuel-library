Puppet::Type.type(:l3_ifconfig).provide(:lnx) do
  defaultfor :osfamily => :linux
  commands   :iproute => 'ip'


  def self.prefetch(resources)
    interfaces = instances
    resources.keys.each do |name|
      if provider = interfaces.find{ |ii| ii.name == name }
        resources[name].provider = provider
      end
    end
  end

  def self.instances
    insts = []
    # parse all system interfaces
    self.get_if_addr_mappings().each_pair do |if_name, pro|
      props = {
        :ensure => :present,
        :name   => if_name,
        :ipaddr => pro[:ipaddr]
      }
      debug("PREFETCHED properties for '#{if_name}': #{props}")
      insts << new(props)
    end
    return insts
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    debug("CREATE resource: #{@resource}")
    @property_flush[:interface] = @resource[:interface]
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    # todo: Destroing of L3 resource -- is a removing any IP addresses.
    #       DO NOT!!! put intedafce to Down state.
    iproute('--force', 'addr', 'flush', 'dev', @resource[:interface])
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
      if ! @property_flush[:ipaddr].nil?
        (@old_property_hash[:ipaddr] - @property_flush[:ipaddr]).each do |ipaddr|
          iproute('--force', 'addr', 'del', ipaddr, 'dev', @resource[:interface])
        end
        (@property_flush[:ipaddr] - @old_property_hash[:ipaddr]).each do |ipaddr|
          iproute('addr', 'add', ipaddr, 'dev', @resource[:interface])
        end
      end
      # if ! @property_flush[:onboot].nil?
      #   iproute('link', 'set', 'dev', @resource[:interface], 'up')
      # end
      @property_hash = resource.to_hash
    end
  end

  #-----------------------------------------------------------------
  # def bridge
  #   @property_hash[:bridge] || :absent
  # end
  # def bridge=(val)
  #   @property_flush[:bridge] = val
  # end

  # def name
  #   @property_hash[:name]
  # end

  def port_type
    @property_hash[:port_type] || :absent
  end
  def port_type=(val)
    @property_flush[:port_type] = val
  end

  def onboot
    @property_hash[:onboot] || :absent
  end
  def onboot=(val)
    @property_flush[:onboot] = val
  end

  def ipaddr
    @property_hash[:ipaddr] || :absent
  end
  def ipaddr=(val)
    @property_flush[:ipaddr] = val
  end

  def gateway
    @property_hash[:gateway] || :absent
  end
  def gateway=(val)
    @property_flush[:gateway] = val
  end

  def dhcp_hostname
    @property_hash[:dhcp_hostname] || :absent
  end
  def dhcp_hostname=(val)
    @property_flush[:dhcp_hostname] = val
  end

  #-----------------------------------------------------------------

  def self.get_if_addr_mappings
    if_list = {}
    ip_a = iproute('-f', 'inet', 'addr', 'show').split(/\n+/)
    #todo: handle error
    if_name = nil
    ip_a.each do |line|
      line.rstrip!
      case line
      when /^\s*\d+\:\s+([\w\-\.]+)[\:\@]/i
        if_name = $1
        if_list[if_name] = { :ipaddr => [] }
      when /^\s+inet\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2})/
        next if if_name.nil?
        if_list[if_name][:ipaddr] << $1
      else
        next
      end
    end
    return if_list
  end

end
