require 'puppetx/l23_utils'
#
module Puppet::Parser::Functions
  newfunction(:get_patch_name, :type => :rvalue) do |arguments|
    if !arguments.is_a? Array or arguments.size != 1 or arguments[0].size != 2
      raise(Puppet::ParseError, "get_patch_name(): Wrong arguments given. " +
        "Should be array of two bridge names.")
    end

    bridges = arguments[0]
    # name shouldn't depend from bridge order
    L23network.get_patch_name(bridges)
  end
end
# vim: set ts=2 sw=2 et :