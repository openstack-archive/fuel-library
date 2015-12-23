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
      @dir_path_modules_local = Noop::Utils.path_from_env 'SPEC_MODULEPATH', 'SPEC_MODULE_PATH'
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

    # Workspace directory where gem bundle will be created
    # is passed from Jenkins or the default value is used
    # @return [Pathname]
    def self.dir_path_workspace
      return @dir_path_workspace if @dir_path_workspace
      @dir_path_workspace = Noop::Utils.path_from_env 'WORKSPACE'
      @dir_path_workspace = Pathname.new '/tmp/noop' unless @dir_path_workspace
      @dir_path_workspace.mkpath
      raise "Workspace '#{@dir_path_workspace}' is not a directory!" unless @dir_path_workspace.directory?
      @dir_path_workspace
    end
  end
end
