require 'pathname'

module Noop
  module Config
    # @return [Pathname]
    def self.dir_name_globals
      Pathname.new 'globals'
    end

    # @return [Pathname]
    def self.dir_path_globals
      dir_path_hiera + dir_name_globals
    end
  end
end
