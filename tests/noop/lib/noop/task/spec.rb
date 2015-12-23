module Noop
  class Task
    # @return [Pathname]
    def file_name_spec
      @file_name_spec
    end

    # @return [Pathname]
    def file_base_spec
      Utils.convert_to_path(file_name_spec.to_s.gsub /_spec\.rb$/, '')
    end

    # @return [Pathname]
    def file_name_spec=(value)
      @file_name_spec = Utils.manifest_to_spec value
    end

    # @return [Pathname]
    def file_name_manifest
      Utils.spec_to_manifest file_name_spec
    end

    # @return [Pathname]
    def file_path_manifest
      Config.dir_path_tasks_local + file_name_manifest
    end

    # @return [Pathname]
    def file_path_spec
      Config.dir_path_task_spec + file_name_spec
    end

    # @return [true,false]
    def file_present_spec
      file_path_spec.readable?
    end

    # @return [Pathname]
    def file_name_task_extension
      Utils.convert_to_path(file_base_spec.to_s.gsub('/', '-') + '.yaml')
    end

  end
end
