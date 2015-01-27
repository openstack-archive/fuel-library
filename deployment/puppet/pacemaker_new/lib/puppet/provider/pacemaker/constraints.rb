module Pacemaker
  module Constraints
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

    # parse constraint rule elements to the rule structure
    # @param element [REXML::Element]
    # @return [Hash<String => Hash>]
    def decode_constraint_rules(element)
      rules = cib_section_constraint_rules element
      return [] unless rules.any?
      rules_array = []
      rules.each do |rule|
        rule_structure = attributes_to_hash rule
        next unless rule_structure['id']
        rule_expressions = children_elements_to_array rule, 'expression'
        rule_structure.store 'expressions', rule_expressions if rule_expressions
        rules_array << rule_structure
      end
      rules_array.sort_by { |rule| rule['id'] }
    end

    # decode a single constraint element to the data structure
    # @param element [REXML::Element]
    # @return [Hash<String => String>]
    def decode_constraint(element)
      return unless element.is_a? REXML::Element
      return unless element.attributes['id']
      return unless element.name

      constraint_structure = attributes_to_hash element
      constraint_structure.store 'type', element.name

      rules = decode_constraint_rules element
      constraint_structure.store 'rules', rules if rules.any?
      constraint_structure
    end

    # constraints found in the CIB
    # filter them by the provided tag name
    # @param type [String] filter this location type
    # @return [Hash<String => Hash>]
    def constraints(type = nil)
      constraints = {}
      cib_section_constraints.each do |constraint|
        constraint_structure = decode_constraint constraint
        next unless constraint_structure
        next unless constraint_structure['id']
        next unless constraint_structure['type'] == type if type
        constraint_structure.delete 'type'
        constraints.store constraint_structure['id'], constraint_structure
      end
      constraints
    end

    # get location constraints and use mnemoisation on the list
    # @return [Hash<String => Hash>]
    def constraint_locations
      return @locations_structure if @locations_structure
      @locations_structure = constraints 'rsc_location'
    end

    # get colocation constraints and use mnemoisation on the list
    # @return [Hash<String => Hash>]
    def constraint_colocations
      return @colocations_structure if @colocations_structure
      @colocations_structure = constraints 'rsc_colocation'
    end

    # get order constraints and use mnemoisation on the list
    # @return [Hash<String => Hash>]
    def constraint_orders
      return @orders_structure if @orders_structure
      @orders_structure = constraints 'rsc_order'
    end

    # construct the constraint unique name
    # from primitive's and node's names
    # @param primitive [String]
    # @param node [String]
    # @return [String]
    def service_location_name(primitive, node)
      "#{primitive}-on-#{node}"
    end

    # add a location constraint to enable a service on a node
    # @param primitive [String] the primitive's name
    # @param node [String] the node's name
    # @param score [Numeric,String] score value
    def service_location_add(primitive, node, score = 100)
      location_structure = {
          'id' => service_location_name(primitive, node),
          'node' => node,
          'rsc' => primitive,
          'score' => score,
      }
      constraint_location_add location_structure
    end

    # check if service location exists for this primitive on this node
    # @param primitive [String] the primitive's name
    # @param node [String] the node's name
    # @return [:true,:false]
    def service_location_exists?(primitive, node)
      id = service_location_name primitive, node
      constraint_location_exists? id
    end

    # add a location constraint
    # @param location_structure [Hash<String => String>] the location data structure
    def constraint_location_add(location_structure)
      location_patch = xml_document %w(diff diff-added cib configuration constraints)
      location_element = xml_rsc_location location_structure
      fail "Could not create XML patch from location '#{location_structure.inspect}'!" unless location_element
      location_patch.add_element location_element
      cibadmin_apply_patch xml_pretty_format location_patch.root
    end

    # remove a location constraint
    # @param id [String] the constraint id
    def constraint_location_remove(id)
      cibadmin_remove "<rsc_location id='#{id}'/>"
    end

    # check if locations constraint exists
    # @param id [String] the constraint id
    # @return [TrueClass,FalseClass]
    def constraint_location_exists?(id)
      constraint_locations.key? id
    end

    # generate rsc_location elements from data structure
    # @param data [Hash]
    # @return [REXML::Element]
    def xml_rsc_location(data)
      return unless data and data.is_a? Hash
      # create an element from the top level hash and skip 'rules' attribute
      # because if should be processed as children elements and useless 'type' attribute
      rsc_location_element = xml_element 'rsc_location', data, %w(rules type), true

      # there are no rule elements
      return rsc_location_element unless data['rules'] and data['rules'].respond_to? :each

      # create a rule element with attributes and treat expressions as children elements
      sort_data(data['rules']).each do |rule|
        next unless rule.is_a? Hash
        rule_element = xml_element 'rule', rule, 'expressions'
        # add expression children elements to the rule element if the are present
        if rule['expressions'] and rule['expressions'].respond_to? :each
          sort_data(rule['expressions']).each do |expression|
            next unless expression.is_a? Hash
            expression_element = xml_element 'expression', expression
            rule_element.add_element expression_element
          end
        end
        rsc_location_element.add_element rule_element
      end
      rsc_location_element
    end

    # generate rsc_colocation elements from data structure
    # @param data [Hash]
    # @return [REXML::Element]
    def xml_rsc_colocation(data)
      return unless data and data.is_a? Hash
      xml_element 'rsc_colocation', data, 'type', true
    end

    # generate rsc_order elements from data structure
    # @param data [Hash]
    # @return [REXML::Element]
    def xml_rsc_order(data)
      return unless data and data.is_a? Hash
      xml_element 'rsc_order', data, 'type', true
    end
  end
end
