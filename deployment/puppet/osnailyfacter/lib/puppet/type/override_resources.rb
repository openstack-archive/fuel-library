Puppet::Type.newtype(:override_resources) do

  newparam(:type) do
    isnamevar
  end

  newparam(:data) do
    defaultto {}
  end

  newparam(:defaults) do
    defaultto {}
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
      else
        debug "#{type}[#{title}]: was not found in the catalog, creating it"
        new_resources << create_resource(type, title, parameters)
      end
    end

    new_resources
  end

end
