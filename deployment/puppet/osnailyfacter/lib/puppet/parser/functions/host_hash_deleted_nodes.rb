Puppet::Parser::Functions::newfunction(
    :host_hash_deleted_nodes,
    :type => :rvalue,
    :arity => 2,
    :doc => <<-EOS
Takes a nodes hash and adds records found in the deleted nodes list.
EOS
) do |argv|
  nodes_hash = argv[0].dup
  fail "Nodes hash should be a Hash. Got: #{nodes_hash.class}!" unless nodes_hash.is_a? Hash

  deleted_nodes_list = argv[1]
  deleted_nodes_list = [deleted_nodes_list] unless deleted_nodes_list.is_a? Array
  deleted_nodes_list.each do |deleted_node|
    deleted_node = deleted_node.to_s
    next if nodes_hash.key? deleted_node
    nodes_hash[deleted_node] = {
      :ensure => 'absent',
    }
  end
  nodes_hash
end

