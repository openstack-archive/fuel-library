class Noop
  module Path
    def spec_dir
      return @spec_dir if @spec_dir
      @spec_dir = File.expand_path File.absolute_path File.dirname(__FILE__)
    end

    def module_path
      return ENV['SPEC_MODULEPATH'] if ENV['SPEC_MODULEPATH']
      return @module_path if @module_path
      @module_path = File.expand_path(File.join(spec_dir, '..', '..', '..', '..', 'deployment', 'puppet'))
    end

    def hiera_data_path
      return ENV['SPEC_YAML_DIR'] if ENV['SPEC_YAML_DIR'] and File.directory? ENV['SPEC_YAML_DIR']
      return @hiera_data_path if @hiera_data_path
      @hiera_data_path = File.expand_path(File.join(spec_dir, '..', '..', 'astute.yaml'))
    end

    def hiera_override_folder
      'override'
    end

    def hiera_globals_folder
      'globals'
    end

    def hiera_facts_folder
      'facts'
    end

    def hiera_task_additional_yaml_file
      return nil unless manifest
      manifest.gsub('/', '-').gsub('.pp', '')
    end

    def hiera_task_override
      override_file = hiera_task_additional_yaml_file
      return nil unless override_file
      File.join hiera_override_folder, override_file
    end

    def hiera_task_override_present?
      return unless override_yaml_path
      File.exists? override_yaml_path
    end

    def hiera_facts_override_present?
      return unless facts_yaml_path
      File.exists? facts_yaml_path
    end

    def astute_yaml_name
      return ENV['SPEC_ASTUTE_FILE_NAME'] if ENV['SPEC_ASTUTE_FILE_NAME']
      'novanet-primary-controller.yaml'
    end

    def astute_yaml_base
      File.basename(astute_yaml_name).gsub(/.yaml$/, '')
    end

    def astute_yaml_path
      File.expand_path File.join hiera_data_path, astute_yaml_name
    end

    def globals_yaml_path
      File.expand_path File.join hiera_globals_folder_path, astute_yaml_name
    end

    def override_yaml_path
      return unless hiera_task_additional_yaml_file
      File.expand_path File.join hiera_override_folder_path, hiera_task_additional_yaml_file + '.yaml'
    end

    def facts_yaml_path
      return unless hiera_task_additional_yaml_file
      File.expand_path File.join hiera_facts_folder_path, hiera_task_additional_yaml_file + '.yaml'
    end

    def hiera_override_folder_path
      File.expand_path File.join hiera_data_path, hiera_override_folder
    end

    def hiera_facts_folder_path
      File.expand_path File.join hiera_data_path, hiera_facts_folder
    end

    def hiera_globals_folder_path
      File.expand_path File.join hiera_data_path, hiera_globals_folder
    end

    def hiera_data_astute
      astute_yaml_base
    end

    def hiera_data_globals
      File.join hiera_globals_folder, hiera_data_astute
    end

    def modular_manifests_node_dir
      '/etc/puppet/modules/osnailyfacter/modular'
    end

    def modular_manifests_local_dir
      File.join module_path, 'osnailyfacter/modular'
    end

  end
  extend Path
end
