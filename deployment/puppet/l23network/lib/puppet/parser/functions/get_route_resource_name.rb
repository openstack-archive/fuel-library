require 'puppetx/l23_utils'
#
module Puppet::Parser::Functions
  newfunction(:get_route_resource_name, :type => :rvalue) do |argv|
    if argv.size < 1 or argv.size > 2
      raise(Puppet::ParseError, "get_route_resource_name(): Wrong arguments given. " +
        "Should be network CIDR (or default) and optionat metric positive value.")
    end

    L23network.get_route_resource_name(argv[0], argv[1])
  end
end
# vim: set ts=2 sw=2 et :