require 'ipaddr'

Puppet::Parser::Functions::newfunction(:format_allocation_pools, :type => :rvalue, :doc => <<-EOS
This function gets floating ranges and format allocation_pools attribute value for neutron subnet resource.
EOS
) do |args|

   raise ArgumentError, ("format_allocation_pools(): wrong number of arguments (#{args.length}; must be 2)") unless args.length == 2

   floating_ranges = args[0]
   floating_cidr = args[1]
   raise ArgumentError, 'format_allocation_pools(): floating_ranges is not array!' if !(floating_ranges.is_a?(Array) or floating_ranges.is_a?(String))
   raise ArgumentError, 'format_allocation_pools(): floating_cidr is missing' if !floating_cidr.is_a?(String)

   debug "Formating allocation_pools for #{floating_ranges} subnet #{floating_cidr}"
   floating_range = IPAddr.new(floating_cidr)
   allocation_pools = []
   if floating_ranges.is_a?(Array) # Is a temporary solution while network_data['L3']['floating'] is not array
     floating_ranges.each do | range |
       range_start, range_end = range.split(':')
       if floating_range.include?(range_start) and floating_range.include?(range_end)
         allocation_pools << "start=#{range_start},end=#{range_end}"
       else
         warning("Skipping #{range} floating IP range because it does not match #{floating_cidr}.")
       end
     end
   else # TODO: remove else part after python part is merged
     allocation_pools << "start=#{floating_ranges.split(':')[0]},end=#{floating_ranges.split(':')[1]}"
   end
   debug("Format is done, value is: #{allocation_pools}")
   allocation_pools
end
