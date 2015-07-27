Puppet::Parser::Functions::newfunction(
    :remove_file,
    :doc => 'Remove a file during the catalog compilation phase'
) do |argv|
  file = argv.first
  break true unless File.file? file
  File.unlink file
  debug("File: '#{file}' was removed!")
end
