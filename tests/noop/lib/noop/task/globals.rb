module Noop
  class Task
    # @return [Pathname]
    def file_path_globals
      Config.dir_path_globals + file_name_hiera
    end

    # @return [true,false]
    def file_present_globals?
      return false unless file_path_globals
      file_path_globals.readable?
    end

    # @return [Pathname]
    def file_name_globals
      file_name_hiera
    end

    # @return [Pathname]
    def file_base_globals
      file_base_hiera
    end

    # @return [Pathname]
    def element_globals
      Config.dir_name_globals + file_base_globals
    end
  end
end
