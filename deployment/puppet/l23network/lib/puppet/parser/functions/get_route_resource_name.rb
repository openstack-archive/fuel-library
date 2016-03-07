begin
  require 'puppetx/l23_utils'
rescue LoadError => e
  rb_file = File.join(File.dirname(__FILE__),'..','..','..','puppetx','l23_utils.rb')
  load rb_file if File.exists?(rb_file) or raise e
end
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