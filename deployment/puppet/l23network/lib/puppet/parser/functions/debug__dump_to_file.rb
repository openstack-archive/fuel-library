require 'yaml'
require 'json'

Puppet::Parser::Functions::newfunction(:debug__dump_to_file, :doc => <<-EOS
    debug output to file

    EOS
) do |argv|
  	File.open(argv[0], 'w'){ |file| file.write argv[1].to_yaml() }
end
# vim: set ts=2 sw=2 et :