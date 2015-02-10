module Puppet::Parser::Functions
  newfunction(:amqp_hosts, :type => :rvalue,
:doc => <<-EOS
Returns the list of amqp host:port blocks separated by comma
EOS
  ) do |arguments|

    raise(Puppet::ParseError, 'No nodes data provided!') if arguments.size < 1

    amqp_nodes  = arguments[0]
    amqp_port   = arguments[1] || '5673'
    prefer_node = arguments[2]

    # split nodes by comma if the are provided as a string
    if amqp_nodes.is_a? String
      amqp_nodes = amqp_nodes.split(',').map { |n| n.strip }
    end
    amqp_nodes = Array(amqp_nodes.dup)

    # rotate nodes array random times (host name as a seed)
    if amqp_nodes.length > 1
      shake_times = function_fqdn_rand([amqp_nodes.length]).to_i
      shake_times.times do
        amqp_nodes.push amqp_nodes.shift
      end
    end

    # move prefered node to the first position if it's present
    if prefer_node and amqp_nodes.include? prefer_node
      amqp_nodes.delete prefer_node
      amqp_nodes.unshift prefer_node
    end

    amqp_nodes.map { |n| "#{n}:#{amqp_port}" }.join ', '
  end
end

# vim: set ts=2 sw=2 et :
