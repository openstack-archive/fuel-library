module Puppet::Parser::Functions
  newfunction(:get_ext_net_name, :type => :rvalue) do |args|
    networks, default_net = args
    ext_net_array = networks.find { |_, value| value.fetch('L2', {})['router_ext'] }
    ext_net_array ? ext_net_array[0] : default_net
  end
end
