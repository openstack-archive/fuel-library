module Pacemaker
  module Status
    # get lrm_rsc_ops section from lrm_resource section CIB section
    # @param lrm_resource [REXML::Element]
    # at /cib/status/node_state/lrm[@id="node-name"]/lrm_resources/lrm_resource[@id="resource-name"]/lrm_rsc_op
    # @return [REXML::Element]
    def cib_section_lrm_rsc_ops(lrm_resource)
      return unless lrm_resource.is_a? REXML::Element
      REXML::XPath.match lrm_resource, 'lrm_rsc_op'
    end

    # get node_state CIB section
    # @return [REXML::Element] at /cib/status/node_state
    def cib_section_node_state
      REXML::XPath.match cib, '//node_state'
    end

    # get lrm_rsc_ops section from lrm_resource section CIB section
    # @param lrm [REXML::Element]
    # at /cib/status/node_state/lrm[@id="node-name"]/lrm_resources/lrm_resource
    # @return [REXML::Element]
    def cib_section_lrm_resources(lrm)
      return unless lrm.is_a? REXML::Element
      REXML::XPath.match lrm, 'lrm_resources/lrm_resource'
    end

    # determine the status of a single operation
    # @param op [Hash<String => String>]
    # @return ['start','stop','master',nil]
    def operation_status(op)
      # skip pendings ops
      # we should waqit until status becomes known
      return if op['op-status'] == '-1'

      if op['operation'] == 'monitor'
        # for monitor operation status is determined by its rc-code
        # 0 - start, 8 - master, 7 - stop, else - error
        case op['rc-code']
          when '0'
            'start'
          when '7'
            'stop'
          when '8'
            'master'
          else
            # not entirely correct but count failed monitor as 'stop'
            'stop'
        end
      elsif %w(start stop promote demote).include? op['operation']
        # if the operation was not successful the status is unknown
        # it will be determined by the next monitor
        # if Pacemaker is unable to bring the resource to a known state
        # it can use STONITH on this node if it's configured
        return unless op['rc-code'] == '0'
        # for a successful start/stop/promote/demote operations
        # we use use master instead of promote and start instead of demote
        if op['operation'] == 'promote'
          'master'
        elsif op['operation'] == 'demote'
          'start'
        else
          op['operation']
        end
      else
        # other operations are irrelevant
        nil
      end
    end

    # determine resource status by parsing its operations
    # it goes from the first operation to the last updating
    # status if it's defined in the end there will be the
    # actual status of this primitive
    # @param ops [Array<Hash>]
    # @return ['start','stop','master',nil]
    # nil means that status is unknown
    def determine_primitive_status(ops)
      status = nil
      ops.each do |op|
        op_status = operation_status op
        status = op_status if op_status
      end
      status
    end

    # decode lrm_resources section of CIB
    # @param lrm_resources [REXML::Element]
    # @return [Hash<String => Hash>]
    def decode_lrm_resources(lrm_resources)
      resources = {}
      lrm_resources.each do |lrm_resource|
        resource = attributes_to_hash lrm_resource
        id = resource['id']
        next unless id
        lrm_rsc_ops = cib_section_lrm_rsc_ops lrm_resource
        next unless lrm_rsc_ops
        ops = decode_lrm_rsc_ops lrm_rsc_ops
        resource.store 'ops', ops
        resource.store 'status', determine_primitive_status(ops)
        resource.store 'failed', failed_operations_found?(ops)
        resources.store id, resource
      end
      resources
    end

    # decode lrm_rsc_ops section of the resource's CIB
    # @param lrm_rsc_ops [REXML::Element]
    # @return [Array<Hash>]
    def decode_lrm_rsc_ops(lrm_rsc_ops)
      ops = []
      lrm_rsc_ops.each do |lrm_rsc_op|
        op = attributes_to_hash lrm_rsc_op
        next unless op['call-id']
        ops << op
      end
      ops.sort { |a, b| a['call-id'].to_i <=> b['call-id'].to_i }
    end

    # get nodes_status structure with resources and their statuses
    # @return [Hash<String => Hash>]
    def node_status
      return @node_status_structure if @node_status_structure
      @node_status_structure = {}
      cib_section_node_state.each do |node_state|
        node = attributes_to_hash node_state
        node_name = node['uname']
        next unless node_name
        lrm = node_state.elements['lrm']
        next unless lrm
        lrm_resources = cib_section_lrm_resources lrm
        next unless lrm_resources
        resources = decode_lrm_resources lrm_resources
        node.store 'primitives', resources
        @node_status_structure.store node_name, node
      end
      @node_status_structure
    end

    # check if operations have same failed operations
    # that should be cleaned up later
    # @param ops [Array<Hash>]
    # @return [TrueClass,FalseClass]
    def failed_operations_found?(ops)
      ops.each do |op|
        # skip incompleate ops
        next unless op['op-status'] == '0'
        # skip useless ops
        next unless %w(start stop monitor promote).include? op['operation']

        # are there failed start, stop
        if %w(start stop promote).include? op['operation']
          return true if op['rc-code'] != '0'
        end

        # are there failed monitors
        if op['operation'] == 'monitor'
          return true unless %w(0 7 8).include? op['rc-code']
        end
      end
      false
    end

    # get a status of a primitive on the entire cluster
    # of on a node if node name param given
    # @param primitive [String]
    # @param node [String]
    # @return [String]
    def primitive_status(primitive, node = nil)
      if node
        node_status.
            fetch(node, {}).
            fetch('primitives', {}).
            fetch(primitive, {}).
            fetch('status', nil)
      else
        statuses = []
        node_status.each do |k, v|
          status = v.fetch('primitives', {}).
              fetch(primitive, {}).
              fetch('status', nil)
          statuses << status
        end
        status_values = {
            'stop' => 0,
            'start' => 1,
            'master' => 2,
        }
        statuses.max_by do |status|
          return unless status
          status_values[status]
        end
      end
    end

    # does this primitive have failed operations?
    # @param primitive [String] primitive name
    # @param node [String] on this node if given
    # @return [TrueClass,FalseClass]
    def primitive_has_failures?(primitive, node = nil)
      return unless primitive_exists? primitive
      if node
        node_status.
            fetch(node, {}).
            fetch('primitives', {}).
            fetch(primitive, {}).
            fetch('failed', nil)
      else
        node_status.each do |k, v|
          failed = v.fetch('primitives', {}).
              fetch(primitive, {}).
              fetch('failed', nil)
          return true if failed
        end
        false
      end
    end

    # determine if a primitive is running on the entire cluster
    # of on a node if node name param given
    # @param primitive [String] primitive id
    # @param node [String] on this node if given
    # @return [TrueClass,FalseClass]
    def primitive_is_running?(primitive, node = nil)
      return unless primitive_exists? primitive
      status = primitive_status primitive, node
      return status unless status
      %w(start master).include? status
    end

    # check if primitive is running as a master
    # either anywhere or on the give node
    # @param primitive [String] primitive id
    # @param node [String] on this node if given
    # @return [TrueClass,FalseClass]
    def primitive_has_master_running?(primitive, node = nil)
      is_multistate = primitive_is_multistate? primitive
      return is_multistate unless is_multistate
      status = primitive_status primitive, node
      return status unless status
      status == 'master'
    end
  end
end
