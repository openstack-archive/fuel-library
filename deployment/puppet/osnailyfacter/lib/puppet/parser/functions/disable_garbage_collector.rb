module Puppet::Parser::Functions
  newfunction(:disable_garbage_collector) do |args|
    GC.disable
  end
end
