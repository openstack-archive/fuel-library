require 'ipaddr'
# require 'yaml'
# require 'puppetx/l23_utils'
require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l3_base')

Puppet::Type.type(:l3_route).provide(:lnx, :parent => Puppet::Provider::L3_base) do
  defaultfor :osfamily => :linux

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
    begin
      self.class.iproute(cmd)
    rescue Exception => e
      if e.to_s =~ /File\s+exists/
        notice("Route for '#{@resource[:destination]}' via #{@resource[:gateway]} already exists. Use existing...")
      else
        raise
      end
    end


    @old_property_hash = {}
    @old_property_hash.merge! @resource
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    cmd = ['--force', 'route', 'del', @property_hash[:destination], 'via', @property_hash[:gateway]]
    cmd << ['metric', @property_hash[:metric]] if @property_hash[:metric] != :absent && @property_hash[:metric].to_i > 0
    self.class.iproute(cmd)
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
          begin
            self.class.iproute(cmd)
          rescue Exception => e
            if e.to_s =~ /File\s+exists/
              notice("Route for '#{@resource[:destination]}' via #{@property_flush[:gateway]} already exists. Use existing...")
            else
              raise
            end
          end
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