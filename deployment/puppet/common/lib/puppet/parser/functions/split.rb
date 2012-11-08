# This function has two modes of operation: 
#
#  split($string, $delimiter) : $string
#
# Split the first argument on every $delimiter. $delimiter is interpreted as
# Ruby regular expression.
#
#  split($string[], $delimiter) : $string[][]
#
# Returns an array of split results with the result of applying split to each
# item from the first argument. 
#
# For long-term portability it is recommended to refrain from using Ruby's
# extended RE features.
module Puppet::Parser::Functions
	newfunction(:split, :type => :rvalue) do |args|
		if args[0].is_a?(Array)
			args.collect do |a| a.split(/#{args[1]}/) end
		else
			args[0].split(/#{args[1]}/)
		end
	end
end
