#  vim: set ts=2 sw=2 tw=0 et :
module Puppet::Parser::Functions
  newfunction(:filter_hash, :type => :rvalue,  :doc => <<-EOS
    Map array of hashes $arguments[0] to an array yielding
    an element from each hash by key $arguments[1]
    EOS
 ) do |arguments|

    raise(Puppet::ParseError, "filter_hash(): Wrong number of arguments " +
      "given (#{arguments.size} for 2") if arguments.size < 2

    value = arguments[0]
    field = arguments[1]

    if value.is_a?(Array)
      value.map do |e|
        e[field]
      end
    else
      []
    end
  end
end
