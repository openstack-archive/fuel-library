module Puppet::Parser::Functions
  newfunction(:ensure_resource_with_default, :type => :statement,
:doc => <<-EOS
Gets a hash of resources and default params, merges default params
into each hash and calls ensure_resource puppet function
EOS
  ) do |arguments|

    raise(Puppet::ParseError, 'Not enough arguments provided. Expected 2 Hashes') if
    arguments.size < 3 or !arguments[1].is_a?(Hash) or !arguments[2].is_a?(Hash)

    resource_type  = arguments[0]
    resources_hash = arguments[1]
    defaults_hash  = arguments[2]
    debug("Defaults hash: #{defaults_hash.inspect}")
    debug("Resources hash: #{resources_hash.inspect}")
    resources_hash.each do |resource,resource_params|
        merged_hash = defaults_hash.merge(resource_params) do |key, defval, val|
          if val.to_sym == :undef or val.is_nil? or val.empty?
            defval
          else
            val
          end
        end
        debug("Merge results: #{merged_hash.inspect}")
        resources_hash[resource] = merged_hash
        function_ensure_resource([resource_type,resource,merged_hash])
    end
  end
end

# vim: set ts=2 sw=2 et :
