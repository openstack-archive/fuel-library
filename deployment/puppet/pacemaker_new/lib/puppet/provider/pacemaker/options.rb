module Pacemaker
  module Options

    def pacemaker_options_file
      File.join File.dirname(__FILE__), 'options.yaml'
    end

    def pacemaker_options
      return @pacemaker_options if @pacemaker_options
      @pacemaker_options = YAML.load_file pacemaker_options_file
    end

  end
end
