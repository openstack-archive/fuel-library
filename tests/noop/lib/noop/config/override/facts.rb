require 'pathname'

module Noop
  module Config
    # @return [Pathname, nil]
    def self.file_name_facts_override
      file_name_task_extension
    end

    # @return [Pathname]
    def self.dir_name_facts_override
      Pathname.new 'facts'
    end

    # @return [Pathname]
    def self.dir_path_facts_override
      dir_path_task_root + dir_name_facts_override
    end

    # @return [Pathname, nil]
    def self.file_path_facts_override
      return unless file_name_facts_override
      dir_path_facts_override + file_name_facts_override
    end

    # @return [true,false]
    def self.file_present_facts_override?
      return unless file_path_facts_override
      file_path_facts_override.readable?
    end
  end
end
