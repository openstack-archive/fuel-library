module Puppet::Parser::Functions
  newfunction(:get_ext_net_name, :type => :rvalue) do |args|
    networks, default_net = args
    begin
      networks.find {|key, value| value['L2']['router_ext'] }[0]
    rescue
      default_net
    else
      default_net
    end
  end
end
