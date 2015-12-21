require 'pathname'

module Noop
  module Config
    # @return [Pathname]
    def self.dir_name_hiera
      Pathname.new 'astute.yaml'
    end

    # @return [Pathname]
    def self.dir_path_hiera
      return @dir_path_hiera if @dir_path_hiera
      @dir_path_hiera = path_from_env 'SPEC_YAML_DIR'
      return @dir_path_hiera if @dir_path_hiera
      @dir_path_hiera = dir_path_task_root + dir_name_hiera
    end

    # @return [Pathname]
    def self.file_name_hiera
      return @file_name_hiera if @file_name_hiera
      @file_name_hiera = path_from_env 'SPEC_ASTUTE_FILE_NAME'
      return @file_name_hiera if @file_name_hiera
      @file_name_hiera = Pathname.new 'novanet-primary-controller.yaml'
    end

    # @return [Pathname]
    def self.file_base_hiera
      file_name_hiera.basename.sub_ext ''
    end

    # @return [Pathname]
    def self.file_path_hiera
      dir_path_hiera + file_name_hiera
    end

    # @return [true,false]
    def self.file_present_hiera?
      return false unless file_path_hiera
      file_path_hiera.readable?
    end

    # @return [Pathname]
    def self.element_hiera
      file_base_hiera
    end
  end
end
