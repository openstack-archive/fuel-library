Puppet::Parser::Functions::newfunction(:nodes_to_node_port_list, :type => :rvalue,:doc => <<-EOS
# we expect to see array on hode hashes here with at least 'name' key present
# for example, [ { 'name' => 'node-1' }, { 'name' => 'node-2' } ]
# second argumnet: port number (default 8084)
# and return: "node-1:8084, node-2:8084" string
# or return empty string if input is incorrect
EOS
) do |argv|
  nodes = argv[0]
  port = argv[1]
  port = '8084' unless port
  return '' unless nodes.is_a? Array and nodes.length > 0
  return '' unless (port.is_a? Numeric and (1..65535).include? port) or (port.is_a? String and port =~ /^\d+$/)
  nodes.select { |n| n.is_a? Hash and n.key? 'name' }.map { |n| "#{n['name']}:#{port}" }.join(', ')
end
