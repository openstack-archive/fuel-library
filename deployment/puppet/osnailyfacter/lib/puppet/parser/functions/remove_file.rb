Puppet::Parser::Functions::newfunction(
    :remove_file,
    :doc => 'Remove a file during the catalog compilation phase'
) do |argv|
  file = argv.first
  if File.file? file
    begin
      File.unlink file
      debug "File: '#{file}' was removed!"
      true
    rescue => e
      debug "File: '#{file}' could not remove! (#{e.message})"
      false
    end
  end
end
