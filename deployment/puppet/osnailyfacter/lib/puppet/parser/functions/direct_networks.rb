Puppet::Parser::Functions::newfunction(:direct_networks, :arity => -2, :type => :rvalue, :doc => <<-EOS
  Parses network endpoints scheme and returns networks
  directly attached to the host
EOS
) do |args|

  endpoints, filter, netmask = args

  allowed_netmask = ['cidr', 'netmask']
  netmask ||= allowed_netmask.first

  raise(
    ArgumentError,
    'direct_networks(): Requires hash as first argument'
  ) unless endpoints.is_a? Hash

  raise(
    ArgumentError,
    "direct_networks(): Expected a string with one of (#{allowed_netmask.join ','}), got #{netmask}"
  ) unless allowed_netmask.include? netmask

  class IPAddr
    def mask_length
      @mask_addr.to_s(2).count '1'
    end

    def cidr_to_netmask(cidr)
      IPAddr.new('255.255.255.255').mask(cidr).to_s
    end

    def cidr
      "#{to_s}/#{mask_length}"
    end

    def netmask
       cidr = "#{mask_length}"
      "#{to_s}/#{cidr_to_netmask(cidr)}"
    end
  end

  networks = []
  get_network = lambda {|ip| networks << IPAddr.new(ip).send(netmask) rescue ''}

  endpoints.each do |interface, opts|
    next unless opts.is_a? Hash
    next if filter && filter != interface

    Array(opts.fetch('IP', [])).each(&get_network)
    Array(opts.fetch('routes', [])).map {|route| route.fetch('net', nil)}.each(&get_network)
  end

  networks.join(' ')
end
