class Noop
  module Path

    # basic paths #

    # tests/noop/spec/lib/noop
    def dirname
      File.absolute_path File.dirname(__FILE__)
    end

    # tests/noop
    def noop_root_path
      return @noop_root_path if @noop_root_path
      @noop_root_path = File.expand_path File.join dirname, '..', '..', '..'
    end

    # tests/noop/spec/hosts
    def spec_hosts_path
      return @hosts_dir if @hosts_dir
      @hosts_dir = File.expand_path File.join noop_root_path, 'spec', 'hosts'
    end

    # tests/noop/astute.yaml
    def astute_yaml_directory_path
      return ENV['SPEC_YAML_DIR'] if ENV['SPEC_YAML_DIR'] and File.directory? ENV['SPEC_YAML_DIR']
      return @hiera_data_path if @hiera_data_path
      @hiera_data_path = File.expand_path File.join noop_root_path, 'astute.yaml'
    end

    # deployment/puppet
    def module_path
      return ENV['SPEC_MODULEPATH'] if ENV['SPEC_MODULEPATH']
      return @module_path if @module_path
      @module_path = File.expand_path File.join noop_root_path, '..', '..', 'deployment', 'puppet'
    end

    # deployment
    def deployment_path
      return @deployment_path if @deployment_path
      @deployment_path = File.expand_path File.join noop_root_path, '..', '..', 'deployment'
    end

    # deployment/puppet/osnailyfacter/modular
    def local_modular_manifests_path
      File.expand_path File.join module_path, 'osnailyfacter', 'modular'
    end

    def node_modular_manifests_path
      '/etc/puppet/modules/osnailyfacter/modular'
    end

    def task_extension_file_name
      return nil unless manifest
      manifest.gsub('/', '-').gsub(/.pp$/, '') + '.yaml'
    end

    # astute yaml file #

    def astute_yaml_file_name
      return ENV['SPEC_ASTUTE_FILE_NAME'] if ENV['SPEC_ASTUTE_FILE_NAME']
      'novanet-primary-controller.yaml'
    end

    def astute_yaml_file_base
      File.basename(astute_yaml_file_name).gsub(/.yaml$/, '')
    end

    def astute_yaml_file_path
      File.expand_path File.join astute_yaml_directory_path, astute_yaml_file_name
    end

    # globals yaml file #

    def globals_folder
      'globals'
    end

    def globals_folder_path
      File.expand_path File.join astute_yaml_directory_path, globals_folder
    end

    def globals_yaml_path
      File.expand_path File.join globals_folder_path, astute_yaml_file_name
    end

    # facts override #

    def facts_override_folder
      'facts'
    end

    def facts_override_present?
      return unless facts_override_path
      File.exists? facts_override_path
    end

    def facts_override_path
      return unless task_extension_file_name
      File.expand_path File.join hiera_facts_folder_path, task_extension_file_name
    end

    def hiera_facts_folder_path
      File.expand_path File.join astute_yaml_directory_path, facts_override_folder
    end

    # yaml override #

    def hiera_override_folder
      'override'
    end

    def yaml_override_path
      return unless task_extension_file_name
      File.expand_path File.join hiera_override_folder_path, task_extension_file_name
    end

    def yaml_override_present?
      return unless yaml_override_path
      File.exists? yaml_override_path
    end

    def hiera_override_folder_path
      File.expand_path File.join astute_yaml_directory_path, hiera_override_folder
    end

    # hiera data elements #

    def hiera_data_astute
      astute_yaml_file_base
    end

    def hiera_data_globals
      File.join globals_folder, hiera_data_astute
    end

    def hiera_data_task_override
      override_file = task_extension_file_name
      return nil unless override_file
      File.join hiera_override_folder, override_file
    end

    # tests #

    # workspace directory where gem bundle will be created
    # is passed from Jenkins or default value is used
    # @@return [String]
    def self.workspace
      workspace = ENV['WORKSPACE']
      unless workspace
        workspace = '/tmp/noop'
        Dir.mkdir workspace unless File.directory? workspace
      end
      unless File.directory? workspace
        raise "Workspace '#{workspace}' is not a directory!"
      end
      workspace
    end

  end
  extend Path
end
