require 'shellwords'
module Puppet::Parser::Functions
  newfunction(:shellescape, :type => :rvalue, :doc => <<-EOS
    Escapes shell charactes.
    EOS
  ) do |arguments|
    raise(Puppet::ParseError, "shellescape(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size != 1
    return Shellwords.escape(arguments[0])
  end
end
