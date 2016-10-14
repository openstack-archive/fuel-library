module PuppetLoader
  def self.load(*files)
    success = files.any? do |file|
      begin
        if file.start_with? './'
          require_relative file
        else
          require file
        end
        Puppet.debug "PuppetLoader: success - '#{file}'"
        true
      rescue LoadError => load_error
        Puppet.warn "PuppetLoader: fail - '#{file}': #{load_error}"
        false
      end
    end
    raise LoadError, "PuppetLoader: could not load any of these files: #{files.join ', '}" unless success
    success
  end
end
