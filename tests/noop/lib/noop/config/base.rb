require 'pathname'

module Noop
  module Config
    # @return [Pathname]
    def self.dir_path_config
      return @dirname if @dirname
      @dirname = Pathname.new(__FILE__).dirname.realpath
    end

    # @return [Pathname]
    def self.dir_path_task_root
      return @dir_path_task_root if @dir_path_task_root
      @dir_path_task_root = dir_path_config.parent.parent.parent
    end

    # @return [Pathname]
    def self.dir_path_repo_root
      return @dir_path_repo_root if @dir_path_repo_root
      @dir_path_repo_root = dir_path_config.parent.parent.parent.parent.parent
    end

    # @return [Pathname]
    def self.dir_path_task_spec
      return @dir_path_task_spec if @dir_path_task_spec
      @dir_path_task_spec = dir_path_task_root + 'spec' + 'hosts'
    end

    # @return [Pathname]
    def self.dir_path_modules_local
      return @dir_path_modules_local if @dir_path_modules_local
      @dir_path_modules_local = path_from_env 'SPEC_MODULEPATH', 'SPEC_MODULE_PATH'
      return @dir_path_modules_local if @dir_path_modules_local
      @dir_path_modules_local = dir_path_repo_root + 'deployment' + 'puppet'
    end

    # @return [Pathname]
    def self.dir_path_tasks_local
      return @dir_path_tasks_local if @dir_path_tasks_local
      @dir_path_tasks_local = dir_path_modules_local + 'osnailyfacter' + 'modular'
    end

    # @return [Pathname]
    def self.dir_path_modules_node
      return @dir_path_modules_node if @dir_path_modules_node
      @dir_path_modules_node = Pathname.new '/etc/puppet/modules'
    end

    # @return [Pathname]
    def self.dir_path_tasks_node
      return @dir_path_tasks_node if @dir_path_tasks_node
      @dir_path_tasks_node = dir_path_modules_node + 'osnailyfacter' + 'modular'
    end

    # @return [Pathname]
    def self.dir_path_deployment
      return @dir_path_deployment if @dir_path_deployment
      @dir_path_deployment = dir_path_repo_root + 'deployment'
    end
  end
end
