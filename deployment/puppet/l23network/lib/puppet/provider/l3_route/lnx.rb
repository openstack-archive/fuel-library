require 'ipaddr'
require 'yaml'
require 'puppetx/l23_utils'

Puppet::Type.type(:l3_route).provide(:lnx) do
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

  def self.get_routes
    # return array of hashes -- all defined routes.
    rv = []
    # cat /proc/net/route returns information about routing table in format:
    # Iface Destination Gateway   Flags RefCnt Use Metric Mask    MTU Window IRTT
    # eth0  00000000    0101010A  0003   0      0    0    00000000 0    0     0
    # eth0  0001010A    00000000  0001   0      0    0    00FFFFFF 0    0     0
    File.open('/proc/net/route').readlines.reject{|l| l.match(/^[Ii]face.+/) or l.match(/^(\r\n|\n|\s*)$|^$/)}.map{|l| l.split(/\s+/)}.each do |line|
      #https://github.com/kwilczynski/facter-facts/blob/master/default_gateway.rb
      iface = line[0]
      metric = line[6]
      # whether gateway is default
      if line[1] == '00000000'
        dest = 'default'
        dest_addr = nil
        mask = nil
        route_type = 'default'
      else
        dest_addr = [line[1]].pack('H*').unpack('C4').reverse.join('.')
        mask = [line[7]].pack('H*').unpack('B*')[0].count('1')
        dest = "#{dest_addr}/#{mask}"
      end
      # whether route is local
      if line[2] == '00000000'
        gateway = nil
        route_type = 'local'
      else
        gateway = [line[2]].pack('H*').unpack('C4').reverse.join('.')
        route_type = nil
      end
      rv << {
        :destination    => dest,
        :gateway        => gateway,
        :metric         => metric.to_i,
        :type           => route_type,
        :interface      => iface,
      }
    end
    # this sort need for prioritize routes by metrics
    return rv.sort_by{|r| r[:metric]||0}
  end

  def self.instances
    rv = []
    routes = get_routes()
    routes.each do |route|
      name = L23network.get_route_resource_name(route[:destination], route[:metric])
      props = {
        :ensure         => :present,
        :name           => name,
      }
      props.merge! route
      props.delete(:metric) if props[:metric] == 0
      debug("PREFETCHED properties for '#{name}': #{props}")
      rv << new(props)
    end
    return rv
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    debug("CREATE resource: #{@resource}")
    @property_flush = {}.merge! @resource
    #todo(sv): check accessability of gateway.
    cmd = ['route', 'add', @resource[:destination], 'via', @resource[:gateway]]
    cmd << ['metric', @resource[:metric]] if @resource[:metric] != :absent && @resource[:metric].to_i > 0
    iproute(cmd)
    @old_property_hash = {}
    @old_property_hash.merge! @resource
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    cmd = ['--force', 'route', 'del', @property_hash[:destination], 'via', @property_hash[:gateway]]
    cmd << ['metric', @property_hash[:metric]] if @property_hash[:metric] != :absent && @property_hash[:metric].to_i > 0
    iproute(cmd)
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
      if @property_flush.has_key? :gateway
        # gateway can't be "absent" by design
        #debug("RES: '#{@resource[:gateway]}', OLD:'#{@old_property_hash[:gateway]}', FLU:'#{@property_flush[:gateway]}'")
        if @old_property_hash[:gateway] != @property_flush[:gateway]
          cmd = ['route', 'change', @resource[:destination], 'via', @property_flush[:gateway]]
          cmd << ['metric', @resource[:metric]] if @resource[:metric] != :absent && @resource[:metric].to_i > 0
          iproute(cmd)
        end
      end

      @property_hash = resource.to_hash
    end
  end

  #-----------------------------------------------------------------
  def destination
    @property_hash[:destination] || :absent
  end
  def destination=(val)
    @property_flush[:destination] = val
  end

  def gateway
    @property_hash[:gateway] || :absent
  end
  def gateway=(val)
    @property_flush[:gateway] = val
  end

  def metric
    @property_hash[:metric] || :absent
  end
  def metric=(val)
    @property_flush[:metric] = val
  end

  def interface
    @property_hash[:interface] || :absent
  end
  def interface=(val)
    @property_flush[:interface] = val
  end

  def type
    @property_hash[:type] || :absent
  end
  def type=(val)
    @property_flush[:type] = val
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