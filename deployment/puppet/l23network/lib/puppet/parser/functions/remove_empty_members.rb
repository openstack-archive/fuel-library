begin
  require 'puppetx/l23_network_scheme'
rescue LoadError => e
  rb_file = File.join(File.dirname(__FILE__),'..','..','..','puppetx','l23_network_scheme.rb')
  load rb_file if File.exists?(rb_file) or raise e
end

module Puppet::Parser::Functions
  newfunction(:remove_empty_members, :type => :rvalue, :doc => <<-EOS
    This function get network_scheme, and remove empty members (who is an empty string)
    from endpoints and interfaces.
    This way is a workaround, because hierahas no ability for remove key from hash.

    EOS
  ) do |argv|
    if !argv[0].is_a? Hash or argv.size != 1
      raise(Puppet::ParseError, "remove_empty_members(hash): Wrong number of arguments or argument type.")
    end

    return L23network.remove_empty_members(argv[0])
  end
end

# vim: set ts=2 sw=2 et :