#
# cidr_to_ipaddr.rb
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
  newfunction(:cidr_to_ipaddr, :type => :rvalue, :doc => <<-EOS
This function get cidr-notated IP addresses and return ip address.
EOS
  ) do |arguments|
    if arguments.size != 1
      raise(Puppet::ParseError, "cidr_to_ipaddr(): Wrong number of arguments " +
        "given (#{arguments.size} for 1)") 
    end

    return prepare_cidr(arguments[0])[0]
  end
end
