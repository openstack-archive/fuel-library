module Pacemaker
  module Resource_defaults
    # get resource defaults CIB section
    # @return [REXML::Element]
    def cib_section_resource_defaults
      REXML::XPath.match(cib, '/cib/configuration/rsc_defaults/meta_attributes').first
    end

    def resource_defaults
      return @resource_defaults_structure if @resource_defaults_structure
      @resource_defaults_structure = children_elements_to_hash cib_section_resource_defaults, 'name'
    end

    def resource_default_value(attribute_name)
      return unless resource_default_defined? attribute_name
      resource_defaults[attribute_name]['value']
    end

    def resource_default_set(attribute_name, attribute_value)
      options = ['--quiet', '--type', 'rsc_defaults', '--attr-name', attribute_name]
      options += ['--attr-value', attribute_value]
      retry_block { crm_attribute_safe options }
    end

    def resource_default_delete(attribute_name)
      options = ['--quiet', '--type', 'rsc_defaults', '--attr-name', attribute_name]
      options += ['--delete-attr']
      retry_block { crm_attribute_safe options }
    end

    def resource_default_defined?(attribute_name)
      return false unless resource_defaults.key? attribute_name
      return false unless resource_defaults[attribute_name].is_a? Hash and resource_defaults[attribute_name]['value']
      true
    end
  end
end
