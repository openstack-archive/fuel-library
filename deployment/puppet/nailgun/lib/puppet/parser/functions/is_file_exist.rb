module Puppet::Parser::Functions
  newfunction(:is_file_exist, :type => :rvalue, :doc => <<-EOS
    This function are checking file's existance.
  EOS
  ) do |args|

    File.exists?(args[0])

  end
end
