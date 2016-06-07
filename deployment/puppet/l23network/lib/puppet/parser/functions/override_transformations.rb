require_relative '../../../puppetx/l23_network_scheme'

module Puppet::Parser::Functions
  newfunction(:override_transformations, :type => :rvalue, :doc => <<-EOS
    This function get network_scheme, and override transformations.
    This way is a workaround, because hiera_hash() function glue arrays inside hashes
    instead override.

    EOS
  ) do |argv|
    if !argv[0].is_a? Hash or argv.size != 1
      raise(Puppet::ParseError, "override_transformations(hash): Wrong number of arguments or argument type.")
    end

    return L23network.override_transformations(argv[0])
  end
end

# vim: set ts=2 sw=2 et :
