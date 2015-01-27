module Pacemaker
  module Properties
    # get cluster property CIB section
    # @return [REXML::Element]
    def cib_section_cluster_property
      REXML::XPath.match(cib, '/cib/configuration/crm_config/cluster_property_set').first
    end

    # get cluster property structure
    # @return [Hash<String => Hash>]
    def cluster_properties
      return @cluster_properties_structure if @cluster_properties_structure
      @cluster_properties_structure = children_elements_to_hash cib_section_cluster_property, 'name'
    end

    # get the value of a cluster property by it's name
    # @param property_name [String] the name of the property
    # @return [String]
    def cluster_property_value(property_name)
      return unless cluster_property_defined? property_name
      cluster_properties[property_name]['value']
    end

    # set the value to this cluster's property
    # @param property_name [String] the name of the property
    # @param property_value [String] the value of the property
    def cluster_property_set(property_name, property_value)
      options = ['--quiet', '--type', 'crm_config', '--name', property_name]
      options += ['--update', property_value]
      retry_block { crm_attribute_safe options }
    end

    # delete this cluster's property
    # @param property_name [String] the name of the property
    def cluster_property_delete(property_name)
      options = ['--quiet', '--type', 'crm_config', '--name', property_name]
      options += ['--delete']
      retry_block { crm_attribute_safe options }
    end

    # check if this property has a value
    # @param property_name [String] the name of the property
    # @return [TrueClass,FalseClass]
    def cluster_property_defined?(property_name)
      return false unless cluster_properties.key? property_name
      return false unless cluster_properties[property_name].is_a? Hash and cluster_properties[property_name]['value']
      true
    end
  end
end
