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
# the configuration structure, and, if the "create" option is set, will create the missing ones.
# The affected Puppet types can be filtered using the "types" and "titles" options. You can provide
# the list of Puppet type names and/or the list of resource titles you want to be processed.
#
Puppet::Type.newtype(:override_resources) do

  newparam(:name) do
    desc 'The uniq name of this override)resources type. Serves no purpose other then reference.'
    isnamevar
  end

  newparam(:configuration) do
    desc 'The configuration data structure to work with.'
    defaultto {}
  end

  newparam(:defaults) do
    desc 'The default parameters. They will be applied to every resource created or updated.'
    defaultto {}
  end

  newparam(:create) do
    desc 'Should this type try to create the new resources in the configuration data or only update the existing ones?'
    defaultto true
  end

  newparam(:types) do
    desc 'The list of Puppet types to process. If the list is empty all the types in the configuration data will be processed.'
  end

  newparam(:titles) do
    desc 'The list of Puppet resource titles to process. If the list is empty all the resources in the configuration data will be processed.'
  end

  def update_resource(type, title, parameters = {})
    fail 'First argument should be the type of the resource!' unless type and not type.empty?
    fail 'Second argument should be the title of the resource!' unless title and not title.empty?
    fail 'Third argument should contain resource parameters hash!' unless parameters.is_a? Hash
    resource = catalog.resource type, title
    unless resource
      debug "#{type}[#{title}]: was not found in the catalog!"
      return
    end
    parameters.each do |parameter, value|
      resource[parameter] = value
    end
    if parameters.has_key?('value') and resource.property('ensure')
      resource['ensure'] = :present
    end
  end

  def create_resource(type, title, parameters = {})
    parameters = parameters.merge(:name => title)
    Puppet::Type.type(type.to_sym).new(parameters)
  end

  def eval_generate
    type = self[:type]
    data = self[:data] || {}
    defaults = self[:defaults] || {}
    create = self[:create]

    fail 'Title should be a resource type to override!' unless type and not type.empty?
    fail 'Data should contain resource hash!' unless data.is_a? Hash
    fail 'Defaults should contain resource defaults hash!' unless defaults.is_a? Hash

    new_resources = []

    data.each do |title, parameters|
      parameters = defaults.merge parameters
      resource = catalog.resource type, title
      if resource
        debug "#{type}[#{title}]: found in the catalog, updating it"
        update_resource type, title, parameters
      elsif create
        debug "#{type}[#{title}]: was not found in the catalog, creating it"
        new_resources << create_resource(type, title, parameters)
      end
    end

    new_resources
  end

end
