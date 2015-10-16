Puppet::Parser::Functions::newfunction(:create_network, :doc => <<-EOS
This function gets network name, predefined_networks hash, segmentation type and create neutron networks.
EOS
) do |args|

  raise ArgumentError, ("create_network(): wrong number of arguments (#{args.length}; must be 3)") if args.length < 3

  network_name = args[0]
  network_data = args[1]
  segmentation_type = args[2]
  fallback_segmantation_id = args[3]

  fallback_segmantation_id = fallback_segmantation_id.first if fallback_segmantation_id.is_a? Array
  fallback_segmantation_id = 1 unless fallback_segmantation_id

  raise ArgumentError, 'create_network(): network_data is not hash!' unless network_data.is_a? Hash
  l2 = network_data.fetch 'L2', {}
  l3 = network_data.fetch 'L3', {}

  tenant_name = network_data.fetch 'tenant', 'admin'
  floating_ranges_data = l3['floating']

  generate_allocation_pool = lambda do |range|
    range = range.split(':') unless range.is_a? Array
    "start=#{range[0]},end=#{range[1]}"
  end

  allocation_pools = []
  if floating_ranges_data and not floating_ranges_data.empty?
    if floating_ranges_data.is_a? Array
      # TODO: Is a temporary solution while network_data['L3']['floating'] is not array
      floating_ranges_data.each do |range|
        allocation_pools << generate_allocation_pool.call(range)
      end
    else
      # TODO: remove else part after python part is merged
      allocation_pools << generate_allocation_pool.call(floating_ranges_data)
    end
  end

  provider_segmentation_id = fallback_segmantation_id
  if %w(vlan gre vxlan).include? segmentation_type
    provider_segmentation_id = l2['segment_id'] if l2['segment_id']
  end

  network_hash = {
      'ensure' => 'present',
      'provider_physical_network' => l2['physnet'] || false,
      'provider_network_type' => segmentation_type,
      'provider_segmentation_id' => provider_segmentation_id,
      'router_external' => l2['router_ext'],
      'tenant_name' => tenant_name,
      'shared' => network_data['shared']
  }

  subnet_hash = {
      'ensure' => 'present',
      'cidr' => l3['subnet'],
      'network_name' => network_name,
      'tenant_name' => tenant_name,
      'gateway_ip' => l3['gateway'],
      'enable_dhcp' => l3['enable_dhcp'],
      'dns_nameservers' => l3['nameservers'],
      'allocation_pools' => allocation_pools,
  }

  debug "Creating neutron_network: '#{network_name}' data: #{network_hash.inspect}"
  function_create_resources(['neutron_network', {
                                                  network_name => network_hash
                                              }])

  debug "Creating neutron_subnet: '#{network_name}__subnet' data: #{subnet_hash.inspect}"
  function_create_resources(['neutron_subnet', {
                                                 "#{network_name}__subnet" => subnet_hash
                                             }])

end
