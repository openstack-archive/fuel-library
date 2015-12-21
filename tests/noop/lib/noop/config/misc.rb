require 'pathname'

module Noop
  module Config
    # Workspace directory where gem bundle will be created
    # is passed from Jenkins or the default value is used
    # @return [Pathname]
    def self.dir_path_workspace
      return @dir_path_workspace if @dir_path_workspace
      @dir_path_workspace = path_from_env 'WORKSPACE'
      @dir_path_workspace = Pathname.new '/tmp/noop' unless @dir_path_workspace
      @dir_path_workspace.mkpath
      raise "Workspace '#{@dir_path_workspace}' is not a directory!" unless @dir_path_workspace.directory?
      @dir_path_workspace
    end

    # @return [Pathname, nil]
    def self.file_name_task_extension
      return unless manifest
      Pathname.new(manifest.gsub('/', '-')).sub_ext '.yaml'
    end

    # @param [Array<String>, String] names
    # @return [Pathname, nil]
    def self.path_from_env(*names)
      names.each do |name|
        name = name.to_s
        return Pathname.new ENV[name] if ENV[name] and File.exists? ENV[name]
      end
      nil
    end

  end
end
