Puppet::Parser::Functions::newfunction(:generate_bridge_mappings, :type => :rvalue, :doc => <<-EOS
This function gets floating ranges and format allocation_pools attribute value for neutron subnet resource.
EOS
) do |args|

   raise ArgumentError, ("generate_bridge_mappings(): wrong number of arguments (#{args.length}; must be 3)") if args.length < 3
   raise ArgumentError, ("generate_bridge_mappings(): wrong number of arguments (#{args.length}; must be 3)") if args.length > 3
   args.each do | arg |
     raise ArgumentError, "generate_bridge_mappings(): #{arg} is not hash!" if !arg.is_a?(Hash)
   end

   neutron_config = args[0]
   network_scheme = args[1]
   flags = args[2]

   #flags = { do_floating => true, do_tenant   => true, do_provider => false }

   if flags[:do_floating]
     net_bridge_map = {}
     floating_networks = []
     neutron_config['predefined_networks'].each do |network, params|
       floating_networks << network if params['L2']['router_ext']
     end
     floating_networks.each do |net|
       physnet = neutron_config['predefined_networks'][net]['L2']['physnet']
       bridge = neutron_config['L2']['phys_nets'][physnet]['bridge'] if neutron_config['L2']['phys_nets'][physnet]
       if ( bridge and !network_scheme['transformations'].select{ |x| x['name'] == bridge }.empty? )
         net_bridge_map[net] = bridge
       end
     end
     net_bridge_map
   end



#   debug "Formating allocation_pools for #{floating_ranges}"
#   debug("Format is done, value is: #{allocation_pools}")
end
