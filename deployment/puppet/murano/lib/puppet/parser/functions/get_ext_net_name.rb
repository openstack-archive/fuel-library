module Puppet::Parser::Functions
  newfunction(:get_ext_net_name, :type => :rvalue) do |args|
    networks, default_net = args
    networks.each do |key, value|
      default_net = key
      break if (value['L2']['router_ext'] == true)
    end
    default_net
  end
end

