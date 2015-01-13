module Puppet::Parser::Functions
  newfunction(:get_ext_net_name, :type => :rvalue) do |args|
    networks = args.first
    fail 'No network data provided!' unless networks.is_a? Hash
    ext_net_array = networks.find { |_, value| value.fetch('L2', {})['router_ext'] }
    break unless ext_net_array
    ext_net_array.first
  end
end
