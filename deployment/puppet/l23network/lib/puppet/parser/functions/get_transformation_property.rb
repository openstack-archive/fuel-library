require 'puppetx/l23_network_scheme'

Puppet::Parser::Functions::newfunction(:get_transformation_property, :type => :rvalue, :doc => <<-EOS
    This function gets an properties from transformations
    and returns information about the selected property

    ex: get_transformation_property('mtu','eth0')

    You can use following modes:
      mtu -- mtu value for the selected transformation.

    Returns NIL if a device is not found or mtu is not set

    EOS
  ) do |argv|
  if argv.size > 1
    mode = argv[0].to_s().upcase()
    argv.shift
  else
      raise(Puppet::ParseError, "get_transformation_property(...): Wrong number of arguments.")
  end

  trans_name = argv.flatten[0]

  rv = L23network.get_property_for_transformation(mode, trans_name, lookupvar('l3_fqdn_hostname'))
  Puppet::debug("get_transformation_property(...): Can't find '#{mode}' value for transformation '#{trans_name}'.") if rv.nil?
  return rv
end

# vim: set ts=2 sw=2 et :
