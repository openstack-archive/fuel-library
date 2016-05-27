begin
  require 'puppetx/l23_network_scheme'
rescue LoadError => e
  rb_file = File.join(File.dirname(__FILE__),'..','..','..','puppetx','l23_network_scheme.rb')
  load rb_file if File.exists?(rb_file) or raise e
end

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