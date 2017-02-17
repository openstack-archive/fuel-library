require 'ipaddr'

module Puppet::Parser::Functions
  newfunction(:get_dhcp_ranges, :doc => <<-EOS
Returns a list of dhcp ranges from a list of admin networks.
  EOS
) do |args|
    admin_nets = args[0]
    unless admin_nets.is_a?(Array) and admin_nets[0].is_a?(Hash)
      raise(Puppet::ParseError, 'Should pass list of hashes as a parameter')
    end
    dhcp_ranges = []
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
        range_comment = "# Environment: #{net['cluster_name']}\n# Nodegroup: #{net['node_group_name']}\n# IP range: #{ip_range}"
        dhcp_range = {
          'comment'        => range_comment,
          'listen_address' => listen_address.join(','),
          'start_address'  => ip_range[0],
          'end_address'    => ip_range[1],
          'netaddr'        => cidr.to_s,
          'netmask'        => netmask,
          'broadcast'      => cidr.to_range.to_a[-1].to_s,
          'gateway'        => net['gateway'],
        }
        debug("Appending dhcp range to the list of ranges: #{dhcp_range.inspect}")
        dhcp_ranges << dhcp_range
      end
    end
    dhcp_ranges
  end
end
