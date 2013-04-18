#
# array_or_string_to_array.rb
#

module Puppet::Parser::Functions
  newfunction(:array_or_string_to_array, :type => :rvalue, :doc => <<-EOS
This function get array or string with separator (comma, colon or space).
and return array without empty or false elements.

*Examples:*

    array_or_string_to_array(['a','b','c','d'])
    array_or_string_to_array('a,b:c d')

Would result in: ['a','b','c','d']
    EOS
  ) do |arguments|
    raise(Puppet::ParseError, "array_or_string_to_array(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size < 1

    in_data = arguments[0]

    if in_data.is_a?(String)
      rv = in_data.split(/[\:\,\s]+/).delete_if{|a| a=='' or !a}
    elsif in_data.is_a?(Array)
      rv = in_data.delete_if{|a| a==''}
    else
      raise(Puppet::ParseError, 'array_or_string_to_array(): Requires array or string to work with')
    end

    return rv
  end
end

# vim: set ts=2 sw=2 et :
