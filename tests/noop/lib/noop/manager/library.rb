require 'yaml'
require 'set'

module Noop
  class Manager

    # @return [Array<Pathname>]
    def spec_file_names
      return @spec_file_names if @spec_file_names
      @spec_file_names = []
      Config.dir_path_task_spec.find do |spec_file|
        next unless spec_file.file?
        next unless spec_file.fnmatch? '*_spec.rb'
        @spec_file_names << spec_file.relative_path_from(Config.dir_path_task_spec)
      end
      @spec_file_names
    end

    # @return [Array<Pathname>]
    def hiera_file_names
      return @hiera_file_names if @hiera_file_names
      @hiera_file_names = []
      Config.dir_path_hiera.find do |hiera_name|
        next unless hiera_name.file?
        next unless hiera_name.fnmatch? '*.yaml'
        @hiera_file_names << hiera_name.relative_path_from(Config.dir_path_hiera)
      end
      @hiera_file_names
    end

    # @return [Array<Pathname>]
    def facts_file_names
      return @facts_file_names if @facts_file_names
      @facts_file_names = []
      Config.dir_path_facts.find do |facts_name|
        next unless facts_name.file?
        next unless facts_name.fnmatch? '*.yaml'
        @facts_file_names << facts_name.relative_path_from(Config.dir_path_facts)
      end
      @facts_file_names
    end

    # @return [Array<Pathname>]
    def task_file_names
      return @task_file_names if @task_file_names
      @task_file_names = []
      Config.dir_path_tasks_local.find do |task_name|
        next unless task_name.file?
        next unless task_name.fnmatch? '*.pp'
        @task_file_names << task_name.relative_path_from(Config.dir_path_tasks_local)
      end
      @task_file_names
    end

    # @return [Hash<String => Hash>]
    def task_graph_metadata
      return @task_graph_metadata if @task_graph_metadata
      @task_graph_metadata = {}

      Config.dir_path_modules_local.find do |task_file|
        next unless task_file.file?
        next unless task_file.fnmatch? '*tasks.yaml'
        begin
          tasks = YAML.load_file task_file
        rescue
          next
        end
        tasks.each do |task|
          id = task['id']
          @task_graph_metadata[id] = task
        end
      end

      @task_graph_metadata.each do |id, group_task|
        next unless group_task['type'] == 'group' and group_task['tasks'].is_a? Array
        group_task['tasks'].each do |task|
          next unless @task_graph_metadata[task]
          @task_graph_metadata[task]['groups'] = [] unless @task_graph_metadata[task]['groups'].is_a? Array
          @task_graph_metadata[task]['groups'] << id
        end
      end

      @task_graph_metadata
    end

    # @return [Hash<Pathname => Set>]
    def assign_spec_to_roles
      return @assign_spec_to_roles if @assign_spec_to_roles
      @assign_spec_to_roles = {}
      task_graph_metadata.values.each do |task_data|
        roles = task_data['groups'] or task_data['roles']
        next unless roles.is_a? Array
        file_path_manifest = task_data.fetch('parameters', {}).fetch('puppet_manifest', nil)
        next unless file_path_manifest
        file_path_manifest = Pathname.new file_path_manifest
        file_name_manifest = file_path_manifest.relative_path_from Config.dir_path_tasks_node
        file_name_spec = Utils.manifest_to_spec file_name_manifest
        roles = Set.new roles
        @assign_spec_to_roles[file_name_spec] = Set.new unless @assign_spec_to_roles[file_name_spec].is_a? Set
        @assign_spec_to_roles[file_name_spec] += roles
      end
      @assign_spec_to_roles
    end

    # @return [Hash<Pathname => Set>]
    def assign_hiera_to_roles
      return @assign_hiera_to_roles if @assign_hiera_to_roles
      @assign_hiera_to_roles = {}
      hiera_file_names.each do |hiera_file|
        begin
          data = YAML.load_file(Config.dir_path_hiera + hiera_file)
          next unless data.is_a? Hash
          nodes = data['nodes']
          uid = data['uid']
          next unless nodes.is_a? Array
          next unless uid
          roles = Set.new
          nodes.each do |node|
            next unless node['uid'] == uid
            next unless node['role']
            roles.add node['role']
          end
          @assign_hiera_to_roles[hiera_file] = roles
        rescue
          next
        end
      end
      @assign_hiera_to_roles
    end

    def assign_spec_to_hiera
      return @assign_spec_to_hiera if @assign_spec_to_hiera
      @assign_spec_to_hiera = {}
      assign_spec_to_roles.each do |file_name_spec, spec_roles|
        hiera_files = assign_hiera_to_roles.select do |file_name_hiera, hiera_roles|
          hiera_roles.intersect? spec_roles
        end.keys
        @assign_spec_to_hiera[file_name_spec] = hiera_files if hiera_files.any?
      end
      @assign_spec_to_hiera
    end

    # @return [Hash<Pathname => Array>]
    def spec_run_metadata
      return @spec_run_metadata if @spec_run_metadata
      @spec_run_metadata = {}
      Config.dir_path_task_spec.find do |spec_file|
        next unless spec_file.file?
        next unless spec_file.fnmatch? '*_spec.rb'
        spec_name = spec_file.relative_path_from(Config.dir_path_task_spec)
        spec_data = parse_spec_file spec_file
        @spec_run_metadata[spec_name] = spec_data if spec_data.any?
      end
      @spec_run_metadata
    end

    # @param [Pathname] task_spec
    def parse_spec_file(task_spec)
      task_spec_metadata = {}

      begin
        text = task_spec.read
        text.split("\n").each do |line|
          line = line.downcase

          if line =~ /^\s*#\s*(?:yamls|hiera):\s*(.*)/
            task_spec_metadata[:hiera] = get_list_of_yamls $1
          end
          if line =~ /^\s*#\s*facts:\s*(.*)/
            task_spec_metadata[:facts] = get_list_of_yamls $1
          end

          if line =~ /^\s*#\s*run:\s*(.*)/
            run_record = get_list_of_yamls $1
            if run_record.length >= 2
              run_record = {
                  :hiera => run_record[0],
                  :facts => run_record[1],
              }
              task_spec_metadata[:runs] = [] unless task_spec_metadata[:runs].is_a? Array
              task_spec_metadata[:runs] << run_record
            end
          end
        end
      rescue
        return task_spec_metadata
      end
      task_spec_metadata
    end

    # @return [Array<Pathname>]
    def get_list_of_yamls(line)
      line = line.split /\s*,\s*|\s+/
      line.map do |yaml|
        yaml = Pathname.new yaml
        yaml = yaml.sub_ext '.yaml' if yaml.extname == ''
        yaml
      end
    end

  end
end
