module Puppet::Parser::Functions
  newfunction(:filter_nodes, :type => :rvalue) do |args|
    name = args[1]
    value  = args[2]
    args[0].select do |it|
      it[name] == value
    end
  end
end