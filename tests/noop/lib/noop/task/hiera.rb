module Noop
  class Task
    # @return [Pathname]
    def file_name_hiera
      return @file_name_hiera if @file_name_hiera
      self.file_name_hiera = Utils.path_from_env 'SPEC_ASTUTE_FILE_NAME'
      return @file_name_hiera if @file_name_hiera
      self.file_name_hiera = Config.default_hiera_file_name
      @file_name_hiera
    end
    alias :hiera :file_name_hiera

    def file_name_hiera=(value)
      return if value.nil?
      @file_name_hiera = Utils.convert_to_path value
      @file_name_hiera = @file_name_hiera.sub_ext '.yaml' if @file_name_hiera.extname == ''
    end
    alias :hiera= :file_name_hiera=

    # @return [Pathname]
    def file_base_hiera
      file_name_hiera.basename.sub_ext ''
    end

    # @return [Pathname]
    def file_path_hiera
      Config.dir_path_hiera + file_name_hiera
    end

    # @return [true,false]
    def file_present_hiera?
      return false unless file_path_hiera
      file_path_hiera.readable?
    end

    # @return [Pathname]
    def element_hiera
      file_base_hiera
    end

    # @return [Pathname]
    def file_name_hiera_override
      file_name_task_extension
    end

    # @return [Pathname]
    def file_path_hiera_override
      Config.dir_path_hiera_override + file_name_hiera_override
    end

    # @return [true,false]
    def file_present_hiera_override?
      return unless file_path_hiera_override
      file_path_hiera_override.readable?
    end

    # @return [Pathname]
    def element_hiera_override
      override_file = file_name_hiera_override
      return unless override_file
      Config.dir_name_hiera_override + override_file.sub_ext('')
    end
  end
end
