require 'ipaddr'
require 'yaml'
require 'puppetx/l23_utils'

Puppet::Type.type(:l3_route).provide(:lnx) do
  defaultfor :osfamily => :linux
  commands   :ip => 'ip'

  def self.prefetch(resources)
    instances.each do |provider|
      resources.each do |name, resource|
        next unless resources[:destination] == provider.destination
        next unless resources[:gateway] == provider.gateway
        next unless resources[:metric] == provider.metric
        debug "L3_route '#{name}' prefetched!"
        resource.provider = provider
      end
    end
  end

  def self.routes
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
        :metric         => metric,
        :type           => route_type,
        :interface      => iface,
      }
    end
    # this sort need for prioritize routes by metrics
    return rv.sort_by {|r| r[:metric].to_i || 0 }
  end

  def self.instances
    instances = []
    routes.each do |route|
      route[:ensure] = :present
      route[:name] = L23network.get_route_resource_name route[:destination], route[:metric]
      debug "PREFETCHED route: #{route.inspect}"
      instances << new(route)
    end
    return instances
  end

  def exists?
    debug 'Call: exists?'
    @property_hash[:ensure] == :present
  end

  def create
    debug 'Call: create'
    @property_hash = {}
    [:destination, :gateway, :metric, :vendor_specific].each do |property|
      @property_hash[property] = @resource[property]
    end
    @property_hash
  end

  def destroy
    debug 'Call: destroy'
    @property_hash = {}
    @property_hash[:ensure] = :absent
  end

  def route_delete
    cmd = ['--force', 'route', 'delete', @property_hash[:destination]]
    cmd += ['via', @property_hash[:gateway]]
    cmd += ['metric', @property_hash[:metric]]
    ip cmd
  end

  def route_add
    cmd = ['--force', 'route', 'add', @property_hash[:destination]]
    cmd += ['via', @property_hash[:gateway]]
    cmd += ['metric', @property_hash[:metric]]
    ip cmd
  end

  def flush
    debug 'Call: flush'
    p @property_hash
  end

  #####################################

  def destination
    @property_hash[:destination]
  end
  def destination=(value)
    @property_flush[:destination] = value
  end

  def gateway
    @property_hash[:gateway]
  end

  def gateway=(value)
    @property_flush[:gateway] = value
  end

  def metric
    @property_hash[:metric]
  end

  def metric=(value)
    @property_flush[:metric] = value
  end

  def interface
    @property_hash[:interface]
  end

  def interface=(value)
    @property_flush[:interface] = value
  end

  def type
    @property_hash[:type]
  end

  def vendor_specific
    @property_hash[:vendor_specific]
  end

  def vendor_specific=(value)
    @property_hash[:vendor_specific] = value
  end

end
# vim: set ts=2 sw=2 et :