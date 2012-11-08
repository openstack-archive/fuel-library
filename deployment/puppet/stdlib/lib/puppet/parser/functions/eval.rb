#
# keys.rb
#

module Puppet::Parser::Functions
  newfunction(:eval, :type => :rvalue, :doc => <<-EOS
Returns evaluated string.
    EOS
  ) do |arguments|

    raise(Puppet::ParseError, "eval(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size < 1
    
    return eval(arguments[0])
  end
end

# vim: set ts=2 sw=2 et :
