require 'pathname'

module Noop
  module Config
    # @return [Pathname. nil]
    def self.file_name_hiera_override
      file_name_task_extension
    end

    # @return [Pathname]
    def self.dir_name_hiera_override
      Pathname.new 'override'
    end

    # @return [Pathname]
    def self.dir_path_hiera_override
      dir_path_hiera + dir_name_hiera_override
    end

    # @return [Pathname, nil]
    def self.file_path_hiera_override
      return unless file_name_hiera_override
      dir_path_hiera_override + file_name_hiera_override
    end

    # @return [true,false]
    def self.file_present_hiera_override?
      return unless file_path_hiera_override
      file_path_hiera_override.readable?
    end

    # @return [Pathname]
    def self.element_hiera_override
      override_file = file_name_hiera_override
      return unless override_file
      dir_name_hiera_override + override_file.sub_ext('')
    end
  end
end
