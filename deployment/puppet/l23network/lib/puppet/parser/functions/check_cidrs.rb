#
# check_cidrs.rb
#
begin
  require 'puppet/parser/functions/lib/prepare_cidr.rb'
rescue LoadError => e
  # puppet apply does not add module lib directories to the $LOAD_PATH (See
  # #4248). It should (in the future) but for the time being we need to be
  # defensive which is what this rescue block is doing.
  rb_file = File.join(File.dirname(__FILE__),'lib','prepare_cidr.rb')
  load rb_file if File.exists?(rb_file) or raise e
end

module Puppet::Parser::Functions
  newfunction(:check_cidrs, :doc => <<-EOS
This function get array of cidr-notated IP addresses and check it syntax.
Raise exception if syntax not right. 
EOS
  ) do |arguments|
    if arguments.size != 1
      raise(Puppet::ParseError, "check_cidrs(): Wrong number of arguments " +
        "given (#{arguments.size} for 1)") 
    end

    cidrs = arguments[0]

    if ! cidrs.is_a?(Array)
      raise(Puppet::ParseError, 'check_cidrs(): Requires array of IP addresses.')
    end
    if cidrs.length < 1
      raise(Puppet::ParseError, 'check_cidrs(): Must given one or more IP address.')
    end

    for cidr in cidrs do
      prepare_cidr(cidr)
    end

    return true
  end
end

# vim: set ts=2 sw=2 et :
