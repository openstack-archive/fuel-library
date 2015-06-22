require 'json'

def array_of_hash?(list)
  return false unless !list.empty? && list.class == Array
  list.each do |e|
    return false unless e.class == Hash
  end
  true
end

module Puppet::Parser::Functions
  newfunction(:check_array_of_hash, :arity =>1, :type => :rvalue, :doc => "Check
 input String is a valid Array of Hash in JSON style") do |arg|
    if arg[0].class == String
      begin
        list = JSON.load(arg[0].gsub("'","\""))
      rescue JSON::ParserError
        raise Puppet::ParseError, "Syntax error: #{arg[0]} is invalid"
      else
        return arg[0] if array_of_hash?(list)
      end
    else
      raise Puppet::ParseError, "Syntax error: #{arg[0]} is not a String"
    end
    return ''
  end
end
