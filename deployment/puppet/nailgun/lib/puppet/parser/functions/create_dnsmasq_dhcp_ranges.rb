require 'ipaddr'
require 'zlib'

module Puppet::Parser::Functions
  newfunction(:create_dnsmasq_dhcp_ranges, :doc => <<-EOS
Creates nailgun::dnsmasq::dhcp_range puppet resources from admin_networks hash.
  EOS
) do |args|
    admin_nets = args[0]
    exclude_nodegroups = args[1] || []
    admin_nets.each do |env_name, env|
      env.each do |nodegroup_name, nodegroup|
        next if exclude_nodegroups.include?(nodegroup_name)
        net = nodegroup['admin']
        net['ip_ranges'].each do |ip_range|
          netmask = IPAddr.new('255.255.255.255').mask(net['cidr'].split('/')[1]).to_s
          print_range = ip_range.join('_')
          resource_name = 'range_' + Zlib::crc32("#{env_name}_#{nodegroup_name}_#{print_range}").to_s
          range_comment = "# Environment: #{env_name}\n# Nodegroup: #{nodegroup_name}\n# IP range: #{ip_range}"
          dhcp_range_resource = {
            resource_name => {
              'file_header'        => "# Generated automatically by puppet\n#{range_comment}",
              'dhcp_start_address' => ip_range[0],
              'dhcp_end_address'   => ip_range[1],
              'dhcp_netmask'       => netmask,
              'dhcp_gateway'       => net['gateway'],
            }
          }
          debug("Trying to create nailgun::dnsmasq::dhcp_range resource #{dhcp_range_resource}")
          function_create_resources(['nailgun::dnsmasq::dhcp_range', dhcp_range_resource])
        end
      end
    end
  end
end
