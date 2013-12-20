module Puppet::Parser::Functions
  newfunction(:calc_ring_part_power, :type => :rvalue) do |args|
    resize_value = args[1]
    nodes = args[0].is_a?(Array) ? args[0] : [ args[0] ]
     dev_number = nodes.inject(0) do |num,node|
       if node['mountpoints']
         add  = node['mountpoints'].split('\n')[0].split.length
         num += add
       else
         num += 2
       end
       num
     end
     ring_power = (Math.log(dev_number * 100)/Math.log(2)).to_int+args[1].to_i
  end
end
