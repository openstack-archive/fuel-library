
Puppet::Parser::Functions::newfunction(:create_network, :doc => <<-EOS
This function gets network name, predefined_networks hash, segmentation type and create neutron networks.
EOS
) do |args|

   network_name = args[0]
   network_data = args[1]
   segmentation_type = args[2]

   raise Puppet::ParseError, 'network_name is empty!' if network_name.nil?
   raise Puppet::ParseError, 'network_data is empty!' if network_data.nil?
   raise Puppet::ParseError, 'segmentation_type is empty!' if segmentation_type.nil?

   tenant_name  = network_data.fetch 'tenant' , 'admin'
   fallback_segment_id = 1

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

   debug("Creating neutron_network #{network_name}")
   function_create_resources(['neutron_network', {
                                network_name => network_hash
   }])

   debug("Creating neutron_subnet #{network_name}__subnet")
   function_create_resources(['neutron_subnet', {
                                "#{network_name}__subnet" => subnet_hash
   }])

end
