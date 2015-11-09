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

    def hiera_override_path
       File.expand_path(File.join(hiera_data_path, hiera_override_folder))
    end

    def hiera_task_override_file
      return nil unless manifest
      manifest.gsub('/', '-').gsub('.pp', '')
    end

    def hiera_task_override
      override_file = hiera_task_override_file
      return nil unless override_file
      File.join hiera_override_folder, override_file
    end

    def astute_yaml_name
      return ENV['SPEC_ASTUTE_FILE_NAME'] if ENV['SPEC_ASTUTE_FILE_NAME']
      'novanet-primary-controller.yaml'
    end

    def astute_yaml_base
      File.basename(astute_yaml_name).gsub(/.yaml$/, '')
    end

    def astute_yaml_path
      File.expand_path(File.join(hiera_data_path, astute_yaml_name))
    end

    def globals_yaml_path
      File.expand_path(File.join(hiera_data_path, globlas_prefix + astute_yaml_name))
    end

    def globlas_prefix
      'globals_yaml_for_'
    end

    def hiera_data_astute
      astute_yaml_base
    end

    def hiera_data_globals
      globlas_prefix + hiera_data_astute
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
