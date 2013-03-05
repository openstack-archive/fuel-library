module Puppet::Parser::Functions
  newfunction(:nodes_to_hash, :type => :rvalue) do |args|
    name = args[1]
    value  = args[2]
    result = {}
    args[0].each do |element|
      result[element[name]] = element[value]
    end
    return result
  end
end