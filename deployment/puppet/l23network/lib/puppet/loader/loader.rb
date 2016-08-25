module PuppetLoader
  def self.debug=(value)
    @debug = value
  end

  def self.debug(message)
    Puppet.debug message if @debug
  end

  def self.load(*files)
    success = files.any? do |file|
      begin
        if file.start_with? './'
          require_relative file
        else
          require file
        end
        debug "PuppetLoader: success - '#{file}'"
        true
      rescue LoadError => load_error
        debug "PuppetLoader: fail - '#{file}': #{load_error}"
        false
      end
    end
    raise LoadError, "PuppetLoader: could not load any of these files: #{files.join ', '}" unless success
    success
  end
end
