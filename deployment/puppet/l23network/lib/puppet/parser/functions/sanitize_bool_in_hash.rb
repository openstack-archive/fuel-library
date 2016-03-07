begin
  require 'puppetx/l23_hash_tools'
rescue LoadError => e
  rb_file = File.join(File.dirname(__FILE__),'..','..','..','puppetx','l23_hash_tools.rb')
  load rb_file if File.exists?(rb_file) or raise e
end

module Puppet::Parser::Functions
  newfunction(:sanitize_bool_in_hash, :type => :rvalue, :doc => <<-EOS
    This function get Hash, recursive convert string implementation
    of true, false, none, null, nil to Puppet/Ruby-specific
    types.

    EOS
  ) do |argv|
    if !argv[0].is_a? Hash or argv.size != 1
      raise(Puppet::ParseError, "sanitize_bool_in_hash(hash): Wrong number of arguments or argument type.")
    end
    # if ! argv[0].is_a? Hash
    #   raise(Puppet::ParseError, "sanitize_bool_in_hash(hash): Argument should be .")
    # end

    return L23network.sanitize_bool_in_hash(argv[0])
  end
end

# vim: set ts=2 sw=2 et :