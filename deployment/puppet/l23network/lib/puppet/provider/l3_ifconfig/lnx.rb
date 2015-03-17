Puppet::Type.type(:l3_ifconfig).provide(:lnx) do
  defaultfor :osfamily => :linux
  commands   :iproute => 'ip',
             :ifup    => 'ifup',
             :ifdown  => 'ifdown'


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
    rou_list = self.get_if_defroutes_mappings()
    # parse all system interfaces
    self.get_if_addr_mappings().each_pair do |if_name, pro|
      props = {
        :ensure         => :present,
        :name           => if_name,
        :ipaddr         => pro[:ipaddr],
      }
      if !rou_list[if_name].nil?
        props.merge! rou_list[if_name]
      else
        props.merge!({
          :gateway => :absent,
          :gateway_metric => :absent
        })
      end
      debug("PREFETCHED properties for '#{if_name}': #{props}")
      insts << new(props)
    end
    return insts
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    debug("CREATE resource: #{@resource}")  # with hash: '#{m}'")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    #p @property_flush
    #p @property_hash
    #p @resource.inspect
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    # todo: Destroing of L3 resource -- is a removing any IP addresses.
    #       DO NOT!!! put intedafce to Down state.
    iproute('--force', 'addr', 'flush', 'dev', @resource[:interface])
    @property_hash.clear
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
    @old_property_hash = {}
    @old_property_hash.merge! @property_hash
  end

  def flush
    if ! @property_flush.empty?
      debug("FLUSH properties: #{@property_flush}")
      #
      # FLUSH changed properties
      if ! @property_flush[:ipaddr].nil?
        if @property_flush[:ipaddr].include?(:absent)
          # flush all ip addresses from interface
          iproute('--force', 'addr', 'flush', 'dev', @resource[:interface])
          #todo(sv): check for existing dhclient for this interface and kill it
        elsif (@property_flush[:ipaddr] & [:dhcp, 'dhcp', 'DHCP']).any?
          # start dhclient on interface the same way as at boot time
          ifdown(@resource[:interface])
          sleep(5)
          ifup(@resource[:interface])
        else
          # add-remove static IP addresses
          if !@old_property_hash.nil? and !@old_property_hash[:ipaddr].nil?
            (@old_property_hash[:ipaddr] - @property_flush[:ipaddr]).each do |ipaddr|
              iproute('--force', 'addr', 'del', ipaddr, 'dev', @resource[:interface])
            end
            adding_addresses = @property_flush[:ipaddr] - @old_property_hash[:ipaddr]
          else
            adding_addresses = @property_flush[:ipaddr]
          end
          if adding_addresses.include? :none
            iproute('--force', 'link', 'set', 'dev', @resource[:interface], 'up')
          elsif adding_addresses.include? :dhcp
            debug("!!! DHCP runtime configuration not implemented now !!!")
          else
            # add IP addresses
            adding_addresses.each do |ipaddr|
              iproute('addr', 'add', ipaddr, 'dev', @resource[:interface])
            end
          end
        end
      end

      if !@property_flush[:gateway].nil? or !@property_flush[:gateway_metric].nil?
        # clean all default gateways for this interface with any metrics
        cmdline = ['route', 'del', 'default', 'dev', @resource[:interface]]
        rc = 0
        while rc == 0
          # we should remove route repeatedly for prevent situation
          # when has multiple default routes through the same router,
          # but with different metrics
          begin
            iproute(cmdline)
          rescue
            rc = 1
          end
        end
        # add new route
        if @resource[:gateway] != :absent
          cmdline = ['route', 'add', 'default', 'via', @resource[:gateway], 'dev', @resource[:interface]]
          if ![nil, :absent].include?(@property_flush[:gateway_metric]) and @property_flush[:gateway_metric].to_i > 0
            cmdline << ['metric', @property_flush[:gateway_metric]]
          end
          begin
            rv = iproute(cmdline)
          rescue
            warn("!!! Iproute can't setup new gateway.\n!!! May be you already have default gateway with same metric:")
            rv = iproute('-f', 'inet', 'route', 'show')
            warn("#{rv}\n\n")
          end
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
    if (@old_property_hash[:ipaddr] - val) != (val - @old_property_hash[:ipaddr])
      @property_flush[:ipaddr] = val
    end
  end

  def gateway
    @property_hash[:gateway] || :absent
  end
  def gateway=(val)
    @property_flush[:gateway] = val
  end

  def gateway_metric
    @property_hash[:gateway_metric] || :absent
  end
  def gateway_metric=(val)
    @property_flush[:gateway_metric] = val
  end

  def dhcp_hostname
    @property_hash[:dhcp_hostname] || :absent
  end
  def dhcp_hostname=(val)
    @property_flush[:dhcp_hostname] = val
  end

  def vendor_specific
    @property_hash[:vendor_specific] || :absent
  end
  def vendor_specific=(val)
    nil
  end

  #-----------------------------------------------------------------

  def self.get_if_addr_mappings
    if_list = {}
    ip_a = iproute('-f', 'inet', 'addr', 'show').split(/\n+/)
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

  def self.get_if_defroutes_mappings
    rou_list = {}
    ip_a = iproute('-f', 'inet', 'route', 'show').split(/\n+/)
    ip_a.each do |line|
      line.rstrip!
      next if !line.match(/^\s*default\s+via\s+([\d\.]+)\s+dev\s+([\w\-\.]+)(\s+metric\s+(\d+))?/)
      metric = $4.nil?  ?  :absent  :  $4.to_i
      rou_list[$2] = { :gateway => $1, :gateway_metric => metric } if rou_list[$2].nil?  # do not replace to gateway with highest metric
    end
    return rou_list
  end


end
# vim: set ts=2 sw=2 et :