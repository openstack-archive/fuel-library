module Puppet::Parser::Functions
  newfunction(:disable_garbage_collector, :type => :statement) { |args| GC.disable }
end
