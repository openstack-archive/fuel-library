require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l3_base')

Puppet::Type.type(:l3_ifconfig).provide(:lnx, :parent => Puppet::Provider::L3_base) do
  defaultfor :osfamily => :linux
  commands   :ifup    => 'ifup',
             :ifdown  => 'ifdown',
             :arping  => 'arping'

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
    self.class.addr_flush(@resource[:interface], true)
    @property_hash.clear
  end

  attr_accessor(:property_flush)
  attr_accessor(:property_hash)
  attr_accessor(:old_property_hash)
  def initialize(value={})
    #debug("INITIALIZE resource: #{value}")
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
          self.class.addr_flush(@resource[:interface], true)
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
              debug(['--force', 'addr', 'del', ipaddr, 'dev', @resource[:interface]])
              self.class.iproute(['--force', 'addr', 'del', ipaddr, 'dev', @resource[:interface]])
            end
            adding_addresses = @property_flush[:ipaddr] - @old_property_hash[:ipaddr]
          else
            adding_addresses = @property_flush[:ipaddr]
          end
          if adding_addresses.include? :none
            self.class.interface_up(@resource[:interface], true)
          elsif adding_addresses.include? :dhcp
            debug("!!! DHCP runtime configuration not implemented now !!!")
          else
            # add IP addresses
            adding_addresses.each do |ipaddr|
              # Check whether IP address is already used
              begin
                arping(['-D', '-f', '-c 32', '-w 2', '-I', @resource[:interface], ipaddr.split('/')[0]])
              rescue Exception => e
                _errmsg = nil
                e.message.split(/\n/).each do |line|
                  line =~ /reply\s+from\s+(\d+\.\d+\.\d+\.\d+)/i
                  if $1
                    _errmsg = line
                    break
                  end
                end
                raise if _errmsg.nil?
                warn("There is IP duplication for IP address #{ipaddr} on interface #{@resource[:interface]}!!!\n#{_errmsg}")
              end
              # Set IP address
              begin
                self.class.iproute(['addr', 'add', ipaddr, 'dev', @resource[:interface]])
              rescue
                rv = self.class.iproute(['-o', 'addr', 'show', 'dev', @resource[:interface], 'to', "#{ipaddr.split('/')[0]}/32"])
                raise if ! rv.join("\n").include? "inet #{ipaddr}"
              end
              # Send Gratuitous ARP to update all neighbours
              arping(['-A', '-c 32', '-w 2', '-I', @resource[:interface], ipaddr.split('/')[0]])
            end
          end
        end
      end

      if !@property_flush[:gateway].nil? or !@property_flush[:gateway_metric].nil?
        # clean all default gateways for *THIS* interface (with any metrics)
        cmdline = ['route', 'del', 'default', 'dev', @resource[:interface]]

        while true
          # we should remove route repeatedly for prevent situation
          # when has multiple default routes through the same router,
          # but with different metrics
          begin
            self.class.iproute(cmdline)
          rescue
            break
          end
        end

        # add new default route
        if @resource[:gateway] != :absent
          # WARNING!!!
          # We shouldn't use 'ip route replace .....' here
          # because *replace* can change gateway in context of another interface.
          # Changing (or removing) gateway for another interface leads to some heavy-diagnostic cases.
          # For manipulate gateways without interface context -- should be used l3_route resource.
          cmdline = ['route', 'add', 'default', 'via', @resource[:gateway], 'dev', @resource[:interface]]
          if ![nil, :absent].include?(@property_flush[:gateway_metric]) and @property_flush[:gateway_metric].to_i > 0
            cmdline << ['metric', @property_flush[:gateway_metric]]
          end
          begin
            self.class.iproute(cmdline)
          rescue
            warn("!!! Iproute can not setup new gateway.\n!!! May be default gateway with same metric already exists:")
            rv = self.class.iproute(['-f', 'inet', 'route', 'show'])
            warn("#{rv.join("\n")}\n\n")
          end
        end
      end

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
end
# vim: set ts=2 sw=2 et :