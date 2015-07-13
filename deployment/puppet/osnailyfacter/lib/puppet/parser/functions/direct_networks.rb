Puppet::Parser::Functions::newfunction(:direct_networks, :type => :rvalue, :doc => <<-EOS
parses network scheme and returns networks
directly attached to the host
EOS
) do |argv|
  endpoints = argv[0]
  network_type = argv[1]
  networks = []

  if defined?(network_type)
    endpoints.each{ |k,v|
      if k == network_type and v.has_key?('IP') and v['IP'].is_a?(Array)
        v['IP'].each { |ip|
          networks << IPAddr.new(ip).to_s + "/" + ip.split('/')[1]
        }
      end
      if k == network_type and v.has_key?('routes') and v['routes'].is_a?(Array)
        v['routes'].each { |route|
          networks << route['net']
        }
      end
    }
  else
    endpoints.each{ |k,v|
      if v.has_key?('IP') and v['IP'].is_a?(Array)
        v['IP'].each { |ip|
          networks << IPAddr.new(ip).to_s + "/" + ip.split('/')[1]
        }
      end
      if v.has_key?('routes') and v['routes'].is_a?(Array)
        v['routes'].each { |route|
          networks << route['net']
        }
      end
    }
  end
  return networks.join(' ')
end
