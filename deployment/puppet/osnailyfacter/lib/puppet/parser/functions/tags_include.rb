module Puppet::Parser::Functions
  newfunction(
      :tags_include,
      :type => :rvalue,
      :arity => 1,
      :doc => <<-EOS
Check if this node's tags include these tags.
EOS
  ) do |args|
    raise Puppet::ParseError, 'Only one argument with tag or array of tags should be provided!' if args.size != 1
    intended_tags = args.first
    intended_tags = [intended_tags] unless intended_tags.is_a? Array
    network_metadata = function_hiera_hash ['network_metadata']
    node_name = function_get_node_key_name []
    node_tags = network_metadata.fetch('nodes', {}).fetch(node_name, {}).fetch('node_tags', [])

    (node_tags & intended_tags).any?
  end
end
