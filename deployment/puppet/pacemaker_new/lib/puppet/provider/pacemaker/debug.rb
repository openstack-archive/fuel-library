module Pacemaker
  module Debug

    def debug_enabled?
      return true if pacemaker_options[:debug_enabled]
      return true if @resource and @resource[:debug]
      false
    end

    def safe_method(cmd, args)
      cmd = cmd.to_sym unless cmd.is_a? Symbol
      if debug_enabled?
        debug ([cmd.to_s] + args).join ' '
        return
      end
      self.send cmd, *args
    end

    def cibadmin_safe(*args)
      safe_method :cibadmin, args
    end

    def crm_node_safe(*args)
      safe_method :crm_node, args
    end

    def cmapctl_safe(*args)
      safe_method :cmapctl, args
    end

    def crm_resource_safe(*args)
      safe_method :crm_resource, args
    end

    def crm_attribute_safe(*args)
      safe_method :crm_attribute, args
    end

################################################################################

    # generate report of primitive statuses by node
    # mostly for debugging
    # @return [Hash]
    def primitives_status_by_node
      report = {}
      return unless node_status.is_a? Hash
      node_status.each do |node_name, node_data|
        primitives_of_node = node_data['primitives']
        next unless primitives_of_node.is_a? Hash
        primitives_of_node.each do |primitive, primitive_data|
          primitive_status = primitive_data['status']
          report[primitive] = {} unless report[primitive].is_a? Hash
          report[primitive][node_name] = primitive_status
        end
      end
      report
    end

    # form a cluster status report for debugging
    # @return [String]
    def cluster_debug_report(tag = nil)
      report = "\n"
      report += 'Pacemaker debug block start'
      report += " at '#{tag}'" if tag
      report += "\n"
      primitives_status_by_node.each do |primitive, data|
        primitive_name = primitive
        primitive_name = primitives[primitive]['name'] if primitives[primitive]['name']
        primitive_type = 'Simple'
        primitive_type = 'Cloned' if primitive_is_clone? primitive
        primitive_type = 'Multistate' if primitive_is_multistate? primitive

        report += "-> #{primitive_type} primitive: '#{primitive_name}'"
        report += ' (M)' unless primitive_is_managed? primitive
        report += "\n"
        nodes = []
        data.keys.sort.each do |node_name|
          node_status = data.fetch node_name
          node_status = '?' unless node_status.is_a? String
          node_status = node_status.upcase
          node_block = "#{node_name}: #{node_status}"
          node_block += ' (F)' if primitive_has_failures? primitive, node_name
          node_block += ' (L)' if service_location_exists? primitive_full_name(primitive), node_name
          nodes << node_block
        end
        report += '   ' + nodes.join(' | ') + "\n"
      end
      pacemaker_options[:debug_show_properties].each do |p|
        report += "* #{p}: #{cluster_property_value p}\n" if cluster_property_defined? p
      end
      report += 'Pacemaker debug block end'
      report += " at '#{tag}'" if tag
      report + "\n"
    end
  end
end
