require 'pathname'

module Noop
  module Config
    # @return [Pathname]
    def self.dir_name_globals
      Pathname.new 'globals'
    end

    # @return [Pathname]
    def self.dir_path_globals
      dir_path_task_root + dir_name_globals
    end

    # @return [Pathname]
    def self.file_path_globals
      dir_path_globals + file_name_hiera
    end

    # @return [true,false]
    def self.file_present_globals?
      return false unless file_path_globals
      file_path_globals.readable?
    end

    # @return [Pathname]
    def self.file_name_globals
      file_name_hiera
    end

    # @return [Pathname]
    def self.file_base_globals
      file_base_hiera
    end

    # @return [Pathname]
    def self.element_globals
      dir_name_globals + file_base_hiera
    end
  end
end
