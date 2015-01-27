module Pacemaker
  module Operation_defaults
    # get operation defaults CIB section
    # @return [REXML::Element]
    def cib_section_operation_defaults
      REXML::XPath.match(cib, '/cib/configuration/op_defaults/meta_attributes').first
    end
  end

  def operation_defaults
    return @operation_defaults_structure if @operation_defaults_structure
    @operation_defaults_structure = children_elements_to_hash cib_section_operation_defaults, 'name'
  end

  def operation_default_value(attribute_name)
    return unless operation_default_defined? attribute_name
    operation_defaults[attribute_name]['value']
  end
  
  def operation_default_set(attribute_name, attribute_value)
    options = ['--quiet', '--type', 'op_defaults', '--attr-name', attribute_name]
    options += ['--attr-value', attribute_value]
    retry_block { crm_attribute_safe options }
  end

  def operation_default_delete(attribute_name)
    options = ['--quiet', '--type', 'op_defaults', '--attr-name', attribute_name]
    options += ['--delete-attr']
    retry_block { crm_attribute_safe options }
  end

  def operation_default_defined?(attribute_name)
    return false unless operation_defaults.key? attribute_name
    return false unless operation_defaults[attribute_name].is_a? Hash and operation_defaults[attribute_name]['value']
    true
  end
end
