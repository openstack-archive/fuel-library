require 'puppet/parser/functions'

Puppet::Parser::Functions::newfunction(:override_resources, :arity => -2, :doc => <<-EOS
Creates of updates resources according to the provided data the same way as
create_resources work.
EOS
) do |argv|
  type = argv[0]

  data = (argv[1].nil? or argv[1].empty?) ? {} : argv[1]
  defaults = (argv[2].nil? or argv[2].empty?) ? {} : argv[2]

  fail 'First argument should be the type of the resource!' unless type and not type.empty?
  fail 'Second arguments should contain resource data hash!' unless data.is_a? Hash
  fail 'Third arguments should contain resource defaults hash!' unless defaults.is_a? Hash

  Puppet::Parser::Functions.function(:create_resources)

  data.each do |title, parameters|
    parameters = defaults.merge parameters
    resource = catalog.resource type, title
    if resource
      debug "override_resources: '#{type}[#{title}]': found in the catalog, updating it"
      resource = catalog.resource type, title
      parameters.each do |parameter, value|
        resource[parameter] = value
      end
    else
      debug "override_resources: '#{type}[#{title}]': was not found in the catalog, creating it"
      function_create_resources [type, { title => parameters }]
    end
  end
end
