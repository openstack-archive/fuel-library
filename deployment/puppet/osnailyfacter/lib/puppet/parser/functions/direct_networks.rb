Puppet::Parser::Functions::newfunction(:direct_networks, :type => :rvalue, :doc => <<-EOS
 parses network scheme and returns networks
 directly attached to the host
 EOS
 ) do |argv|

  endpoints = argv[0]
  networks = []

  endpoints.each{ |k,v|
    if v['IP'].is_a?(Array)
      v['IP'].each { |ip|
        networks << IPAddr.new(ip).to_s + "/" + ip.split('/')[1]
      }
    end
  }
  return networks.join(' ')
end
