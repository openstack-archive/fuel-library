require 'ipaddr'
require 'zlib'

module Puppet::Parser::Functions
  newfunction(:create_dnsmasq_dhcp_ranges, :doc => <<-EOS
Creates fuel::dnsmasq::dhcp_range puppet resources from list of admin networks.
  EOS
) do |args|
    admin_nets = args[0]
    unless admin_nets.is_a?(Array) and admin_nets[0].is_a?(Hash)
      raise(Puppet::ParseError, 'Should pass list of hashes as a parameter')
    end
    admin_nets.each do |net|
      next unless net['ip_ranges'].is_a? Array
      net['ip_ranges'].each do |ip_range|
        # loop through local facts to pull which interface has an IP in the
        # dhcp range so we can properly listen on the interface for dhcp
        # messages
        cidr = IPAddr.new(net['cidr'])
        listen_address = []
        interfaces = lookupvar('interfaces')
        if ! interfaces.nil?
          interfaces.split(',').each do |interface|
            local_address = lookupvar("ipaddress_#{interface}")
            listen_address.push(local_address) if cidr.include?(local_address)
          end
        end
        netmask = IPAddr.new('255.255.255.255').mask(net['cidr'].split('/')[1]).to_s
        print_range = ip_range.join('_')
        resource_name = sprintf("range_%08x", Zlib::crc32("#{print_range}_#{net['cidr']}").to_i)
        range_comment = "# Environment: #{net['cluster_name']}\n# Nodegroup: #{net['node_group_name']}\n# IP range: #{ip_range}"
        dhcp_range_resource = {
          resource_name => {
            'file_header'        => "# Generated automatically by puppet\n#{range_comment}",
            'listen_address'     => listen_address.join(','),
            'dhcp_start_address' => ip_range[0],
            'dhcp_end_address'   => ip_range[1],
            'dhcp_netmask'       => netmask,
            'dhcp_gateway'       => net['gateway'],
          }
        }
        debug("Trying to create fuel::dnsmasq::dhcp_range resource: #{dhcp_range_resource.inspect}")
        function_create_resources(['fuel::dnsmasq::dhcp_range', dhcp_range_resource])
      end
    end
  end
end
