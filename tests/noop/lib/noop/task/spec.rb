module Noop
  class Task
    # @return [Pathname]
    def file_name_spec
      @file_name_spec
    end

    # @return [Pathname]
    def file_name_spec=(value)
      @file_name_spec = Utils.convert_to_path value
      @file_name_spec = @file_name_spec.sub /\.pp$/, '_spec.rb'
      @file_name_spec
    end

    # @return [Pathname]
    def file_name_manifest
      Utils.convert_to_path file_name_spec.to_s.gsub /_spec\.rb$/, '.pp'
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
      Utils.convert_to_path(file_name_manifest.sub_ext('').to_s.gsub('/', '-') + '.yaml')
    end

  end
end
