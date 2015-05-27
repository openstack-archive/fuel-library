module Puppet::Parser::Functions
  newfunction(:disable_garbage_collector) { GC.disable }
end
