require 'pathname'

module Noop
  module Config
    # @return [Pathname]
    def self.dir_name_hiera
      Pathname.new 'hiera'
    end

    # @return [Pathname]
    def self.dir_path_hiera
      return @dir_path_hiera if @dir_path_hiera
      @dir_path_hiera = Noop::Utils.path_from_env 'SPEC_YAML_DIR'
      return @dir_path_hiera if @dir_path_hiera
      @dir_path_hiera = dir_path_task_root + dir_name_hiera
    end

    # @return [Pathname]
    def self.dir_name_hiera_override
      Pathname.new 'override'
    end

    # @return [Pathname]
    def self.dir_path_hiera_override
      dir_path_hiera + dir_name_hiera_override
    end
  end
end
