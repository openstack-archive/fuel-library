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
  end
end
