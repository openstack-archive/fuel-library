module Puppet::Parser::Functions
  newfunction(:filter_nodes_with_enabled_option, :type => :rvalue, :doc => <<-EOS
  Return a list of hosts (fqdn) where selected option is enabled
  Argument1: nodes hash (network_metadata)
  Argument2: string: option to look for
  Returns: a list of nodes
  EOS
  ) do |args|

    if args.size != 2
      raise Puppet::ParseError, 'This function takes exactly 2 arguments.'
    end

    nodes  = args[0]
    option = args[1]

    unless nodes.is_a?(Hash)
      raise Puppet::ParseError, 'The first argument must be a hash'
    end

    unless option.is_a?(String)
      raise Puppet::ParseError, 'The second argument must be a string'
    end

    filtered_nodes = []
    nodes.each do |node, node_hash|
      if node_hash.fetch(option, false) == true
        filtered_nodes.push node_hash['fqdn']
      end
    end
    filtered_nodes

  end
end
