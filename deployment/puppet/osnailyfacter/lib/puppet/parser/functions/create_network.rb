Puppet::Parser::Functions::newfunction(:create_network, :doc => <<-EOS
This function gets network name, predefined_networks hash, segmentation type and create neutron networks.
EOS
) do |args|

   raise ArgumentError, ("create_network(): wrong number of arguments (#{args.length}; must be 3)") if args.length < 3

   network_name = args[0]
   network_data = args[1]
   segmentation_type = args[2]
   segment_id_range  = args[3]
   if segment_id_range
     fallback_segment_id = segment_id_range[0]
   else
     fallback_segment_id = 1
   end

   raise ArgumentError, 'create_network(): network_data is not hash!' if !network_data.is_a?(Hash)

   tenant_name  = network_data.fetch 'tenant' , 'admin'

   if floating_ranges = network_data['L3']['floating'] and !network_data['L3']['floating'].empty?
     allocation_pools = []
     if floating_ranges.is_a?(Array) # Is a temporary solution while network_data['L3']['floating'] is not array
       floating_ranges.each do | range |
         allocation_pools << "start=#{range.split(':')[0]},end=#{range.split(':')[1]}"
       end
     else # TODO: remove else part after python part is merged
       allocation_pools << "start=#{floating_ranges.split(':')[0]},end=#{floating_ranges.split(':')[1]}"
     end
   end

   provider_segmentation_id = nil
   if ['vlan', 'gre', 'vxlan'].include?(segmentation_type)
     provider_segmentation_id = network_data['L2']['segment_id'] ? network_data['L2']['segment_id'] : fallback_segment_id
   end

   network_hash = {
    'ensure' => 'present',
    'provider_physical_network' => network_data['L2']['physnet'] ? network_data['L2']['physnet'] : false ,
    'provider_network_type' => segmentation_type,
    'provider_segmentation_id' => provider_segmentation_id,
    'router_external' => network_data['L2']['router_ext'],
    'tenant_name' => tenant_name,
    'shared' => network_data['shared']
   }

   subnet_hash = {
    'ensure' => 'present',
    'cidr' => network_data['L3']['subnet'],
    'network_name' => network_name,
    'tenant_name' => tenant_name,
    'gateway_ip' => network_data['L3']['gateway'],
    'enable_dhcp' => network_data['L3']['enable_dhcp'],
    'dns_nameservers' => network_data['L3']['nameservers'],
    'allocation_pools' => allocation_pools,
   }

   debug("Creating neutron_network #{network_name} #{network_hash}")
   function_create_resources(['neutron_network', {
                                network_name => network_hash
   }])

   debug("Creating neutron_subnet #{network_name}__subnet #{subnet_hash}")
   function_create_resources(['neutron_subnet', {
                                "#{network_name}__subnet" => subnet_hash
   }])

end
