# Prefixes arguments 2..n with first argument.
#
#  prefix_with(string prefix, string[] arguments) : string[]
#
# Example:
#
#  prefix_with("php-", [ "blah", "foo" ])
#
# will result in this array:
#
#  [ "php-blah", "php-foo" ]
#
module Puppet::Parser::Functions
	newfunction(:prefix_with, :type => :rvalue) do |args|
		prefix = args.shift
		args.collect {|v| "%s%s" % [prefix, v] }
	end
end

