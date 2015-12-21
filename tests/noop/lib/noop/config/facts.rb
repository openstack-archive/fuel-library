require 'pathname'

module Noop
  module Config
    # @return [Pathname]
    def self.dir_name_facts
      Pathname.new 'facts'
    end

    # @return [Pathname]
    def self.dir_path_facts
      return @dir_path_facts if @dir_path_facts
      @dir_path_facts = Noop::Utils.path_from_env 'SPEC_FACTS_DIR'
      return @dir_path_facts if @dir_path_facts
      @dir_path_facts = dir_path_task_root + dir_name_facts
    end

    # @return [Pathname]
    def self.dir_name_facts_override
      Pathname.new 'facts'
    end

    # @return [Pathname]
    def self.dir_path_facts_override
      dir_path_task_root + dir_name_facts_override
    end
  end
end
