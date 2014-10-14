module Puppet::Parser::Functions
  newfunction(:get_ext_net_name, :type => :rvalue) do |args|
    networks, default_net = args
    networks.find {|key, value| value['L2']['router_ext'] }[0] or default_net
  end
end
