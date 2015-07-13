Puppet::Parser::Functions::newfunction(:direct_networks, :type => :rvalue, :doc => <<-EOS
parses network scheme and returns networks
directly attached to the host
EOS
) do |argv|
  endpoints = argv[0]
  filter = argv[1]
  networks = []

  class IPAddr
    def mask_length
      @mask_addr.to_s(2).count '1'
    end

    def cidr
      "#{to_s}/#{mask_length}"
    end
  end

  endpoints.each do |interface, parameters|
    next unless parameters.has_key? 'IP' and parameters['IP'].is_a? Array
    next if filter and interface != filter
    parameters['IP'].each do |ip|
      next unless ip
      networks << IPAddr.new(ip).cidr
    end
    next unless parameters.has_key? 'routes' and parameters['routes'].is_a? Array
    parameters['routes'].each do |route|
      next unless route.has_key? 'net'
      networks << IPAddr.new(route['net']).cidr
    end
  end
  return networks.join(' ')
end

