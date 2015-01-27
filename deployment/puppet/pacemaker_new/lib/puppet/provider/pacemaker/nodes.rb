module Pacemaker
  module Nodes
    # get nodes CIB section
    # @return [REXML::Element] at /cib/configuration/nodes
    def cib_section_nodes
      REXML::XPath.match cib, '/cib/configuration/nodes/*'
    end

    # hostname of the current node
    # @return [String]
    def node_name
      return @node_name if @node_name
      @node_name = crm_node('-n').chomp.strip
    end
    alias :hostname :node_name

    # the nodes structure
    # uname => id
    # @return [Hash<String => Hash>]
    def nodes
      return @nodes_structure if @nodes_structure
      @nodes_structure = {}
      cib_section_nodes.each do |node_block|
        node = attributes_to_hash node_block
        next unless node['id'] and node['uname']
        @nodes_structure.store node['uname'], node
      end
      @nodes_structure
    end
  end
end
