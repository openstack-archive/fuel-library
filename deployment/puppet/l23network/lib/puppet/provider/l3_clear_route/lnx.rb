require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l3_clear_route).provide(:lnx) do
  defaultfor :osfamily   => :linux
  commands   :ip         => 'ip'


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
      rv << {
        :destination    => dest,
        :metric         => metric.to_i,
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

  def destroy
    debug("DESTROY resource: #{@resource}")
    cmd = ['--force', 'route', 'del', @resource[:destination]]
    cmd << ['metric', @resource[:metric]] if @resource[:metric] != :absent && @resource[:metric].to_i > 0
    ip(cmd)
    @property_hash.clear
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
    @old_property_hash = {}
    @old_property_hash.merge! @property_hash
  end
  #-----------------------------------------------------------------
  def destination
    @property_hash[:destination] || :absent
  end
  def destination=(val)
    @property_flush[:destination] = val
  end

  def metric
    @property_hash[:metric] || :absent
  end
  def metric=(val)
    @property_flush[:metric] = val
  end
end
# vim: set ts=2 sw=2 et :
