require 'puppet'
require 'puppet/parameter/boolean'

# This Puppet metatype's purpose is to update the parameters of other type in the catalog
# with the values from the configuration data structure, or even create the new ones.
#
# Configuration structure:
#
# configuration:
#   nova_config:
#     DEFAULT/debug
#       ensure: present
#       value: true
#     DEFAULT/verbose
#       ensure: absent
#
#   file:
#     test_file:
#       ensure: present
#       path: /tmp/test
#       content: 123
#     web_file:
#       ensure: present
#       path: /var/www/html/index.html
#       content: '<html/>'
#
#   service:
#     apache:
#       ensure: running
#       enable: true
#       require: File[web_file]
#
# Applying this structure will update the parameters of specified resources to the values in
# the configuration structure. If the "create" option is enabled the missing resources will be added to
# the catalog.
#
# Configuration options:
#  # These two options allows you to provide a list of resource types and/or resource titles
#  # which should be processed by this override_resources instance. If the lists are missing
#  # or empty no filtering will be used and all resources types and titles will be processed.
#  types_filter: []
#  titles_filter: []
#  # Enable the creation of all resources. New instances will be added to the catalog if an
#  # existing instance have not been found there.
#  create: true/false
#  # These two options allows you to set the exception lists for the new resource creation.
#  # If the "create" option is set to true, these lists of types and titles are used as
#  # the list of resources that should not be created. The resources mentioned in the lists
#  # will not be created and the resources not mentioned in the lists will be created.
#  # If the "create" option is set to false, these lists of types and titles are used as
#  # the list of resources that should be created. The resources mentioned in the lists
#  # will be created and the resources not mentioned in the lists will not be created.
#  types_create_exception: []
#  titles_create_exception: []
#  # This structure allows you to set the default parameters for every Puppet type.
#  # If you want all resources of the same type to share the same parameter value
#  # (i.e. ensure: present) you can set this value for all resources of this type here.
#  # The value wil be added to every updated or created resource of this type unless
#  # the other value is provided for a resource in the configuration data.
#  defaults:
#    <type>:
#      <parameter>: <value>
#
# These options can be set as the "options" parameter, or can be accessed individually
# trough the corresponding resource parameters which will override the values set in the
# "options" structure.
#
# Example usage:
#
# override_resources { 'my_test_override' :
#   configuration  => hiera_hash('configuration', {}),
#   options        => hiera_hash('configuration_options', {}),
#   # you can locally override the values in the hiera options like this
#   # types_filter => ['package','service'],
#   # create       => false,
# }
#
Puppet::Type.newtype(:override_resources) do

  newparam(:name) do
    desc 'The uniq name of this override)resources type. Serves no purpose other then reference.'
    isnamevar
  end

  newparam(:configuration) do
    desc 'The configuration data structure to work with.'
    defaultto {}
    validate do |value|
      fail "Configuration data should contain a resources hash! Got: #{value.class}" unless value.is_a? Hash
    end
  end

  newparam(:options) do
    desc 'The options data structure to work with.'
    defaultto {}
    validate do |value|
      fail "Options data should contain an options hash! Got: #{value.class}" unless value.is_a? Hash
    end
  end

  newparam(:types_filter, :array_matching => :all) do
    desc 'The list of Puppet types to process. If the list is empty all the types in the configuration data will be processed.'
    defaultto []
  end

  newparam(:titles_filter, :array_matching => :all) do
    desc 'The list of Puppet resource titles to process. If the list is empty all the resources in the configuration data will be processed.'
    defaultto []
  end

  newparam(:create, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Should this type try to create the new resources in the configuration data or only update the existing ones?'
  end

  newparam(:types_create_exception, :array_matching => :all) do
    desc 'The list of Puppet types that should be created if the "create" option is not set, or, not created, if the "create" option is set.'
    defaultto []
  end

  newparam(:titles_create_exception, :array_matching => :all) do
    desc 'The list of Puppet titles that should be created if the "create" option is not set, or, not created, if the "create" option is set.'
    defaultto []
  end

  newparam(:defaults) do
    desc 'The default parameters. This data structure should be a hash with the type name as a key and a hash of default parameters as a value.'
    defaultto {}
    validate do |value|
      fail "Defaults data should contain a defaults hash! Got: #{value.class}" unless value.is_a? Hash
    end
  end

##########

  # Get the configuration data structure
  # @return [Hash<String>]
  def configuration
    self[:configuration] || {}
  end

  # Get the options data structure
  # @return [Hash<String>]
  def options
    self[:options] || {}
  end

  # Get the list of filtered in types
  # @return [Array<String>]
  def types_filter
    types_filter = self[:types_filter] || []
    return types_filter if types_filter.any?
    options.fetch 'types_filter', []
  end

  # Get the list of filtered in titles
  # @return [Array<String>]
  def titles_filter
    titles_filter = self[:titles_filter] || []
    return titles_filter if titles_filter.any?
    options.fetch 'titles_filter', []
  end

  # Get the value of the create option
  # @return [true,false]
  def create?
    create = self[:create]
    return create unless create.nil?
    options.fetch 'create', false
  end

  # Get the list of type create exceptions
  # @return [Array<String>]
  def types_create_exception
    types_create_exception = self[:types_create_exception] || []
    return types_create_exception if types_create_exception.any?
    options.fetch 'types_create_exception', []
  end

  # Get the list of title create exceptions
  # @return [Array<String>]
  def titles_create_exception
    titles_create_exception = self[:titles_create_exception] || []
    return titles_create_exception if titles_create_exception.any?
    options.fetch 'titles_create_exception', []
  end

  # Get the defaults data structure
  # @return [Hash<String>]
  def defaults
    defaults = self[:defaults] || {}
    return defaults if defaults.any?
    options.fetch 'defaults', {}
  end

##########
  # Check if this type should be created
  # either by the create value or by the exception
  # @param [String] type
  # @return [true,false]
  def type_create?(type)
    if create?
      not types_create_exception.include? type
    else
      types_create_exception.include? type
    end
  end

  # Check if this title should be created
  # either by the create value or by the exception
  # @param [String] title
  # @return [true,false]
  def title_create?(title)
    if create?
      not titles_create_exception.include? title
    else
      titles_create_exception.include? title
    end
  end

  # Check if this type's processing is enabled
  # or the filter is empty
  # @param [String] type
  # @return [true,false]
  def type_enabled?(type)
    return true unless types_filter.any?
    types_filter.include? type
  end

  # Check if this title's processing is enabled
  # or the filter is empty
  # @param [String] title
  # @return [true,false]
  def title_enabled?(title)
    return true unless titles_filter.any?
    titles_filter.include? title
  end

  # Get the default parameters for a given type
  # @param [String] type
  # @return [Hash<String>]
  def defaults_for(type)
    default_parameters = defaults.fetch type.to_s, {}
    fail "Default for the type: #{type} should be a hash of parameters. Got: #{default_parameters.inspect}" unless default_parameters.is_a? Hash
    default_parameters
  end

  # Find a resource in the catalog and set its parameters
  # to the provided values.
  # @param [String] type
  # @param [String] title
  # @param [Hash<String>] parameters
  def update_resource(type, title, parameters = {})
    resource = catalog.resource type, title
    unless resource
      debug "#{type}[#{title}]: was not found in the catalog!"
      return false
    end
    parameters.each do |parameter, value|
      resource[parameter] = value
    end
    true
  end

  # Check if a resource with the given type and title
  # is present in the catalog.
  # @param [String] type
  # @param [String] title
  # @return [true,false]
  def resource_present?(type, title)
    !!catalog.resource(type, title)
  end

  # Create a new resource by the Puppet type name,
  # resource title and parameters and return the instance.
  # @param [String] type
  # @param [String] title
  # @param [Hash<String>] parameters
  # @return [Puppet::Type]
  def create_resource(type, title, parameters = {})
    parameters = parameters.merge(:name => title)
    Puppet::Type.type(type.to_sym).new(parameters)
  end

  # The main method of this metatype. Updates the existing resources
  # according to the configuration, and, if crete is enabled,
  # returns the array of the new resources that should be added to
  # the catalog.
  # @return [Array<Puppet::Type>]
  def eval_generate
    new_resources = []
    configuration.each do |type, resources|
      fail "The 'type' should be the name of the Puppet type and not be empty! Got: #{type.inspect}" unless type and not type.empty?
      fail "The 'resources' should be a hash with the override Puppet resources! Got: #{resources.inspect}" unless resources.is_a? Hash
      next unless type_enabled? type
      debug "Processing type: #{type}"
      resources.each do |title, parameters|
        fail "The 'title' should be the title of the Puppet resource nd should not be empty! Got: #{title.inspect}" unless title and not title.empty?
        fail "The 'parameters' should be a hash of the resource parameters! Got: #{parameters.inspect}" unless parameters.is_a? Hash
        next unless title_enabled? title
        debug "Processing resource: #{type}[#{title}]"
        parameters = defaults_for(type).merge parameters

        if resource_present? type, title
          debug "#{type.capitalize}[#{title}] was found in the catalog, updating it!"
          update_resource type, title, parameters
        else
          if type_create? type or title_create? title
            debug "#{type.capitalize}[#{title}] was not found in the catalog, creating it!"
            new_resources << create_resource(type, title, parameters)
          else
            debug "#{type.capitalize}[#{title}] was not found in the catalog, skipping it!"
            next
          end
        end

      end
    end
    new_resources
  end

end
