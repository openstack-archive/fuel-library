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
    raise(Puppet::ParseError, "merge_arrays(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size < 1

    rv = []

    for arg in arguments
      if arg.is_a?(Array)
        rv += arg
      else
        raise(Puppet::ParseError, 'merge_arrays(): Requires only array as argument')
      end
    end

    return rv
  end
end

# vim: set ts=2 sw=2 et :
