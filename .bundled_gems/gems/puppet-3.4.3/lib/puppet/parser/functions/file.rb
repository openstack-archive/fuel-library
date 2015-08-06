# Returns the contents of a file

Puppet::Parser::Functions::newfunction(
  :file, :arity => -2, :type => :rvalue,
  :doc => "Return the contents of a file.  Multiple files
  can be passed, and the first file that exists will be read in."
) do |vals|
    ret = nil
    vals.each do |file|
      unless Puppet::Util.absolute_path?(file)
        raise Puppet::ParseError, "Files must be fully qualified"
      end
      if Puppet::FileSystem::File.exist?(file)
        ret = File.read(file)
        break
      end
    end
    if ret
      ret
    else
      raise Puppet::ParseError, "Could not find any files from #{vals.join(", ")}"
    end
end
