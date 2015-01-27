module Pacemaker
  module Xml
    # create a new xml document
    # @param path [String,Array<String>] create this sequence of path elements
    # @param root [REXML::Document] use existing element as a root instead of creating a new one
    # @return [REXML::Element] element point to the last path component
    # use .root to get the document root
    def xml_document(path, root = nil)
      root = REXML::Document.new unless root
      element = root
      path = Array(path) unless path.is_a? Array
      path.each do |component|
        element = element.add_element component
      end
      element
    end

    # convert hash to xml element
    # @param tag [String] what xml tag to create
    # @param hash [Hash] attributes data structure
    # @param skip_attributes [String,Array<String>] skip these hash keys
    # @return [REXML::Element]
    def xml_element(tag, hash, skip_attributes = nil)
      return unless hash.is_a? Hash
      element = REXML::Element.new tag
      hash.each do |attribute, value|
        attribute = attribute.to_s
        # skip attributes that were specified to be skipped
        next if skip_attributes == attribute or
            (skip_attributes.respond_to? :include? and skip_attributes.include? attribute)
        # skip array and hash values. add only scalar ones
        next if value.is_a? Array or value.is_a? Hash
        element.add_attribute attribute, value
      end
      element
    end

    def xml_primitive(data)
      return unless data and data.is_a? Hash
      primitive_skip_attributes = %w(name parent instance_attributes operations meta_attributes utilization)
      primitive_element = xml_element 'primitive', data, primitive_skip_attributes

      # instance attributes
      if data['instance_attributes'].respond_to? :each and data['instance_attributes'].any?
        instance_attributes_document = xml_document 'instance_attributes', primitive_element
        instance_attributes_document.add_attribute 'id', data['id'] + '-instance_attributes'
        sort_data(data['instance_attributes']).each do |instance_attribute|
          instance_attribute_element = xml_element 'nvpair', instance_attribute
          instance_attributes_document.add_element instance_attribute_element if instance_attribute_element
        end
      end

      # meta attributes
      if data['meta_attributes'].respond_to? :each and data['meta_attributes'].any?
        complex_meta_attributes_document = xml_document 'meta_attributes', primitive_element
        complex_meta_attributes_document.add_attribute 'id', data['id'] + '-meta_attributes'
        sort_data(data['meta_attributes']).each do |meta_attribute|
          meta_attribute_element = xml_element 'nvpair', meta_attribute
          complex_meta_attributes_document.add_element meta_attribute_element if meta_attribute_element
        end
      end

      # operations
      if data['operations'].respond_to? :each and data['operations'].any?
        operations_document = xml_document 'operations', primitive_element
        sort_data(data['operations']).each do |operation|
          operation_element = xml_element 'op', operation
          operations_document.add_element operation_element if operation_element
        end
      end

      # complex structure
      if data['complex'].is_a? Hash and data['complex']['type']
        skip_complex_attributes = 'type'
        supported_complex_types = %w(clone master meta_attributes)
        complex_tag_name = data['complex']['type']
        return unless supported_complex_types.include? complex_tag_name
        complex_element = xml_element complex_tag_name, data['complex'], skip_complex_attributes

        # complex meta attributes
        if data['complex']['meta_attributes'].respond_to? :each and data['complex']['meta_attributes'].any?
          complex_meta_attributes_document = xml_document 'meta_attributes', complex_element
          complex_meta_attributes_document.add_attribute 'id', data['complex']['id'] + '-meta_attributes'
          sort_data(data['complex']['meta_attributes']).each do |meta_attribute|
            complex_meta_attribute_element = xml_element 'nvpair', meta_attribute
            complex_meta_attributes_document.add_element complex_meta_attribute_element if complex_meta_attribute_element
          end
        end

        complex_element.add_element primitive_element
        return complex_element
      end

      primitive_element
    end

    # generate rsc_location elements from data structure
    # @param data [Hash]
    # @return [REXML::Element]
    def xml_rsc_location(data)
      return unless data and data.is_a? Hash
      # create an element from the top level hash and skip 'rules' attribute
      # because if should be processed as children elements and useless 'type' attribute
      rsc_location_element = xml_element 'rsc_location', data, %w(rules type)

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
      xml_element 'rsc_colocation', data, 'type'
    end

    # generate rsc_order elements from data structure
    # @param data [Hash]
    # @return [REXML::Element]
    def xml_rsc_order(data)
      return unless data and data.is_a? Hash
      xml_element 'rsc_order', data, 'type'
    end

    # output xml element as the actual xml text with indentation
    # @param element [REXML::Element]
    # @return [String]
    def xml_pretty_format(element)
      return unless element.is_a? REXML::Element
      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true
      xml=''
      formatter.write element, xml
      xml + "\n"
    end
  end
end

# make rexml's attributes to be sorted by their name
# when iterating throuth them
# instead of randomly placing them each time
module REXML
  class Attributes
    def each_value # :yields: attribute
      keys.sort.each do |key|
        yield fetch key
      end
    end
  end
end
