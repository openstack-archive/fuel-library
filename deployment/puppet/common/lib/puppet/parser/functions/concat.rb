# concat.rb

# concatenate the contents of arrays
# Use it like this:
# $base_metrics = ['a', 'b']
# $extended_metrics = ['c']
# $metrics = concat($base_metrics, $extended_metrics)
module Puppet::Parser::Functions
	newfunction(:concat, :type => :rvalue) do |args|
		result = []
		args.each do |arg|
			result = result.concat(arg)
		end
		result
	end
end

