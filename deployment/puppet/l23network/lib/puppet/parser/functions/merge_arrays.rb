#
# merge_arrays.rb
#

module Puppet::Parser::Functions
  newfunction(:merge_arrays, :type => :rvalue, :doc => <<-EOS
This function get arrays, merge it and return.

*Examples:*

    merge_arrays(['a','b'], ['c','d'])
   

Would result in: ['a','b','c','d']
    EOS
  ) do |arguments|
    raise(Puppet::ParseError, "merge_arrays(): Wrong number of arguments
      given (#{arguments.size} for 2)") unless arguments.size == 2

    (Array(arguments[0]) + Array(arguments[1])).sort
  end
end

# vim: set ts=2 sw=2 et :
