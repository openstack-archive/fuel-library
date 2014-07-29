require"puppet"

module Puppet::Parser::Functions
  newfunction(:file_exists_simple, :type => :rvalue) do |args|
    if File.exists?(args[0])
      return
    else
      return 0
    end
  end
end