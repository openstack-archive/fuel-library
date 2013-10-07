begin
  require 'puppet/parser/functions/lib/hash_tools.rb'
rescue LoadError => e
  # puppet apply does not add module lib directories to the $LOAD_PATH (See
  # #4248). It should (in the future) but for the time being we need to be
  # defensive which is what this rescue block is doing.
  rb_file = File.join(File.dirname(__FILE__),'lib','hash_tools.rb')
  load rb_file if File.exists?(rb_file) or raise e
end

module Puppet::Parser::Functions
  newfunction(:sanitize_bool_in_hash, :type => :rvalue, :doc => <<-EOS
    This function get Hash, recursive convert string implementation
    of true, false, none, null, nil to Puppet/Ruby-specific
    types.

    EOS
  ) do |argv|
    if argv.size != 1
      raise(Puppet::ParseError, "sanitize_bool_in_hash(hash): Wrong number of arguments.")
    end

    return L23network.sanitize_bool_in_hash(argv[0])
  end
end

# vim: set ts=2 sw=2 et :