# This function has two modes of operation:
#
#  basename(string) : string
#
# Returns the last component of the filename given as argument, which must be
# formed using forward slashes ("/") regardless of the separator used on the
# local file system.
#
#  basename(string[]) : string[]
#
# Returns an array of strings with the basename of each item from the argument.
#
module Puppet::Parser::Functions
	newfunction(:basename, :type => :rvalue) do |args|
		if args[0].is_a?(Array)
			args.collect do |a| File.basename(a) end
		else
			File.basename(args[0])
		end
	end
end

