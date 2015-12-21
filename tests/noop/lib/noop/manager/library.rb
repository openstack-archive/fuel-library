module Noop
  class Manager

    # @return [Array<Pathname>]
    def all_spec_names
      return @all_spec_names if @all_spec_names
      @all_spec_names = []
      Config.dir_path_task_spec.find do |spec_name|
        next unless spec_name.file?
        next unless spec_name.fnmatch? '*_spec.rb'
        @all_spec_names << spec_name.relative_path_from(Config.dir_path_task_spec)
      end
      @all_spec_names
    end

    # @return [Array<Pathname>]
    def all_hiera_names
      return @all_hiera_names if @all_hiera_names
      @all_hiera_names = []
      Config.dir_path_hiera.find do |hiera_name|
        next unless hiera_name.file?
        next unless hiera_name.fnmatch? '*.yaml'
        @all_hiera_names << hiera_name.relative_path_from(Config.dir_path_hiera)
      end
      @all_hiera_names
    end

    # @return [Array<Pathname>]
    def all_facts_names
      return @all_facts_names if @all_facts_names
      @all_facts_names = []
      Config.dir_path_facts.find do |facts_name|
        next unless facts_name.file?
        next unless facts_name.fnmatch? '*.yaml'
        @all_facts_names << facts_name.relative_path_from(Config.dir_path_facts)
      end
      @all_facts_names
    end

    # @return [Array<Pathname>]
    def all_task_names
      return @all_task_names if @all_task_names
      @all_task_names = []
      Config.dir_path_tasks_local.find do |task_name|
        next unless task_name.file?
        next unless task_name.fnmatch? '*.pp'
        @all_task_names << task_name.relative_path_from(Config.dir_path_tasks_local)
      end
      @all_task_names
    end

  end
end
