require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l3_clear_route).provide(:lnx) do
  defaultfor :osfamily   => :linux
  commands   :ip         => 'ip'

  def self.prefetch(resources)
    instances.each do |provider|
      name = provider.name.to_s
      next unless resources.key? name
      resources[name].provider = provider
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
        :metric         => metric.to_i,
        :gateway        => gateway,
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
    info("\n Does not support 'ensure=present' \n It could be 'ensure=absent' ONLY!!! ")
  end

  def route_delete
    cmd = [ '--force', 'route', 'delete', @property_hash[:destination] ]
    cmd += [ 'via', @property_hash[:gateway] ]
    cmd += [ 'metric', @property_hash[:metric] ] if @property_hash[:metric]
    ip cmd
  end

  def destroy
    debug "Call: destroy"
    self.class.instances.each do |provider|
      # we remove only routes with the same destination and metric as described one
      next unless provider.destination == @resource[:destination] and provider.metric == @resource[:metric]
      # we do not remove routes that have the same gateway as described one
      next if provider.gateway == @resource[:gateway]
      # other providers should remove their routes
      provider.route_delete
    end
  end

  def flush
    debug 'Call: flush'
  end

  #-----------------------------------------------------------------

  def destination
    @property_hash[:destination]
  end

  def destination=(val)
    @property_flush[:destination] = val
  end

  def metric
    @property_hash[:metric]
  end

  def metric=(val)
    @property_flush[:metric] = val
  end

  def gateway
    @property_hash[:gateway]
  end

  def gateway=(val)
    @property_flush[:gateway] = val
  end

end
# vim: set ts=2 sw=2 et :
