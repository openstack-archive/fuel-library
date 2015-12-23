module Noop
  module Utils
    # @param [Array<String>, String] names
    # @return [Pathname, nil]
    def self.path_from_env(*names)
      names.each do |name|
        name = name.to_s
        return convert_to_path ENV[name] if ENV[name] and File.exists? ENV[name]
      end
      nil
    end

    # @param [Object] value
    # @return [Pathname]
    def self.convert_to_path(value)
      value = Pathname.new value.to_s unless value.is_a? Pathname
      value
    end

    def self.spec_to_manifest(spec)
      manifest = spec.to_s.gsub /_spec\.rb$/, '.pp'
      convert_to_path manifest
    end

    def self.manifest_to_spec(manifest)
      spec = manifest.to_s.gsub /\.pp$/, '_spec.rb'
      convert_to_path spec
    end

    def self.run(command)
      puts "Run: #{command}"
    end
  end
end
