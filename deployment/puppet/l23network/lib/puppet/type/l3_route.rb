require 'yaml'
require 'ipaddr'
require 'puppet/parameter/boolean'

class IPAddr
  def mask_length
    @mask_addr.to_s(2).count '1'
  end

  def cidr
    "#{to_s}/#{mask_length}"
  end
end

Puppet::Type.newtype(:l3_route) do
  desc 'Manage a network routings.'

  ensurable

  newparam(:name) do
    desc 'The title of this route'
  end

  newproperty(:destination) do
    desc 'Destination network'

    munge do |value|
      value = '0.0.0.0/0' if value == 'default'
      value = '0.0.0.0/0' if value == '0.0.0.0'
      value = IPAddr.new value
      value = value.cidr
      value
    end

    validate do |value|
      next if value == 'default'
      fail "Destination '#{value}' is not an IP address!" unless @resource.is_ip? value
    end

  end

  newproperty(:gateway) do
    desc 'Gateway'

    validate do |value|
      fail "Gateway '#{value}' is not an IP address!" unless @resource.is_ip? value
    end

  end

  newproperty(:metric) do
    desc 'Route metric'
    newvalues %r(^\d+$)

    defaultto { '0' }

    validate do |value|
      int_metric = value.to_i
      fail 'Metric is not a number!' unless int_metric.to_s == value
      min_metric = 0
      max_metric = 65535
      fail "Metric should be more then '#{min_metric}'!" unless int_metric >= min_metric
      fail "Metric should be less then '#{max_metric}'!" unless int_metric <= max_metric
    end

  end

  newproperty(:interface) do
    desc 'The interface name'
    newvalues %r(^[a-z_][0-9a-z\.\-_]*[0-9a-z]$)
  end

  newproperty(:vendor_specific) do
    desc 'Hash of vendor specific properties'

    validate do |value|
      fail 'Vendor_specific should be a hash!' unless value.is_a? Hash
    end

    munge do |value|
      break unless value.any?
      L23network.reccursive_sanitize_hash value
    end

    def should_to_s(value)
      value.inspect
    end

    def is_to_s(value)
      value.inspect
    end

    def insync?(value)
      should == value
    end
  end

  newparam(:debug, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc %q(Don't actually do any changes)
    defaultto { false }
  end

  newparam(:purge, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc %q(Purge other unmanaged routes to the same destination and with the same metric)
    defaultto { false }
  end

  autorequire(:l2_port) do
    [self[:interface]]
  end

  def is_ip?(value)
    begin
      ip = IPAddr.new value
      ip.is_a? IPAddr
    rescue
      false
    end
  end

  def generate
    routes_to_remove = []
    return routes_to_remove unless purge?
    discovered_routes.each do |discovered_route|
      # do not remove a route if the same route is managed by catalog
      next if catalog_routes.find do |catalog_route|
        catalog_route[:destination] == discovered_route.provider.destination and
            catalog_route[:metric] == discovered_route.provider.metric
      end
      discovered_route[:ensure] = :absent
      discovered_route[:debug] = self[:debug]
      discovered_route[:purge] = false
      debug "Generate #{discovered_route.inspect} to purge it!"
      routes_to_remove << discovered_route
    end
    routes_to_remove
  end

  def inspect
    route = "L3_route[#{self[:name]}]"
    route += " (#{self[:destination]}, #{self[:metric]})" if
        self[:destination] and self[:metric]
    route += " [#{self.provider.destination}, #{self.provider.metric}]" if
        self.provider and self.provider.destination and self.provider.metric
    route
  end

  def catalog_resources
    self.catalog.resources
  end

  def catalog_routes
    catalog_resources.select do |resource|
      resource.is_a? Puppet::Type.type :l3_route
    end
  end

  def discovered_routes
    self.class.instances.select do |resource|
      # drop local-link routes
      next false unless resource.provider.gateway
      true
    end
  end

  def validate
    return unless self.catalog
    duplicate = catalog_routes.find do |catalog_route|
      catalog_route[:destination] == self[:destination] and
          catalog_route[:metric] == self[:metric]
    end
    return unless duplicate
    fail "#{duplicate.inspect} is a duplicate of #{self.inspect} because they have the same destination and metric!"
  end

end
# vim: set ts=2 sw=2 et :
