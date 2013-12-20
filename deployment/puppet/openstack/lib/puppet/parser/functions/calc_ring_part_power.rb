module Puppet::Parser::Functions
  newfunction(:calc_ring_part_power, :type => :rvalue) do |args|
    nodes = args[0].is_a? Array ? args[0] : [ args[0] ]
    dev_number = nodes.inject do |num,node|
      if node['mountpoints']
        num += 2
      else 
        num += node['mountpoints'].split('\n')[0].split.length
      end
    end  
    ring_power = (Math.log(dev_number * 100)/Math.log(2)).to_int+1
  end 
end
