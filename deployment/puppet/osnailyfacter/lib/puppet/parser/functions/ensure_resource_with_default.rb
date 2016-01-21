module Puppet::Parser::Functions
  newfunction(:ensure_resource_with_default, :type => :statement,
:doc => <<-EOS
Gets a hash of resources and default params, merges default params
into each hash and calls ensure_resource puppet function
EOS
  ) do |arguments|

    raise(Puppet::ParseError, 'Not enough arguments provided. Expected 2 Hashes') if
    arguments.size < 3 or !arguments[0].is_a?(Hash) or !arguments[1].is_a?(Hash)

    resource_type  = arguments[0]
    resources_hash = arguments[1]
    defaults_hash  = arguments[2]

    resources_hash.each do |resource,resource_params|
        resources_hash['resource'] = defaults_hash.merge(resource_params)
    end
    function_ensure_resource(resource_type,resources_hash)
  end
end

# vim: set ts=2 sw=2 et :
