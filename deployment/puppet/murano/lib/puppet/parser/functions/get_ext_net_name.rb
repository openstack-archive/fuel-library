module Puppet::Parser::Functions
  newfunction(:get_ext_net_name, :type => :rvalue) do |args|
    networks, default_net = args
    ext_net.find { |key, value| value.fetch('L2', {})['router_ext'] }[0] rescue default_net
  end
end
