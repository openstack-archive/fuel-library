require 'yaml'
require 'ipaddr'

Puppet::Type.newtype(:l3_route) do
  desc 'Manage a network routings.'

  ensurable

  newparam(:name) do
    desc 'The title of this route'
  end

  newproperty(:destination) do
    desc 'Destination network'

    munge do |value|
      value = '0.0.0.0' if value == 'default'
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

  newproperty(:type) do
    desc 'RO field, type of route'
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

  end

  def catalog_routes
    @resource.catalog.resources.select do |resource|
      resource.is_a? Puppet::Type.type :l3_route
    end
  end

end
# vim: set ts=2 sw=2 et :