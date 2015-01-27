module Pacemaker
  module Cib
    # get the raw CIB from Pacemaker
    # @return [String] cib xml
    def raw_cib
      return File.read @cib_file if @cib_file
      @raw_cib = cibadmin '-Q'
      if !@raw_cib or @raw_cib == ''
        fail 'Could not dump CIB XML!'
      end
      @raw_cib
    end
    attr_accessor :cib_file

    # create a new REXML CIB document
    # @return [REXML::Document] at '/'
    def cib
      return @cib if @cib
      @cib = REXML::Document.new(raw_cib)
    end

    ##############################################################################

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
    def cib_section_nodes_state
      REXML::XPath.match cib, '//node_state'
    end

    # get all 'primitive' sections from CIB
    # @return [Array<REXML::Element>] at /cib/configuration/resources/primitive
    def cib_section_primitives
      REXML::XPath.match cib, '//primitive'
    end

    # get lrm_rsc_ops section from lrm_resource section CIB section
    # @param lrm [REXML::Element]
    # at /cib/status/node_state/lrm[@id="node-name"]/lrm_resources/lrm_resource
    # @return [REXML::Element]
    def cib_section_lrm_resources(lrm)
      return unless lrm.is_a? REXML::Element
      REXML::XPath.match lrm, 'lrm_resources/lrm_resource'
    end

    # get all 'rsc_location', 'rsc_order' and 'rsc_colocation' sections from CIB
    # @return [Array<REXML::Element>] at /cib/configuration/constraints/*
    def cib_section_constraints
      REXML::XPath.match cib, '//constraints/*'
    end

    # get all rule elements from the constraint element
    # @return [Array<REXML::Element>] at /cib/configuration/constraints/*/rule
    def cib_section_constraint_rules(constraint)
      return unless constraint.is_a? REXML::Element
      REXML::XPath.match constraint, 'rule'
    end

    # get cluster property CIB section
    # @return [REXML::Element]
    def cib_section_cluster_property
      REXML::XPath.match(cib, '/cib/configuration/crm_config/cluster_property_set').first
    end

    # get resource defaults CIB section
    # @return [REXML::Element]
    def cib_section_resource_defaults
      REXML::XPath.match(cib, '/cib/configuration/rsc_defaults/meta_attributes').first
    end

    # get operation defaults CIB section
    # @return [REXML::Element]
    def cib_section_operation_defaults
      REXML::XPath.match(cib, '/cib/configuration/op_defaults/meta_attributes').first
    end

    ##############################################################################

    # apply the XML patch to CIB
    # @param xml [String, REXML::Element] the patch to apply
    def cibadmin_apply_patch(xml)
      xml = xml_pretty_format xml if xml.is_a? REXML::Element
      retry_block { cibadmin '--force', '--patch', '--sync-call', '--xml-text', xml.to_s }
    end

    # ask cibadmin to remove the first element matchig the input
    # @param xml [String, REXML::Element]
    def cibadmin_remove(xml)
      xml = xml_pretty_format xml if xml.is_a? REXML::Element
      retry_block { cibadmin '--force', '--delete', '--sync-call', '--xml-text', xml.to_s }
    end
  end
end
