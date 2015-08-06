# Bundler and rubygems maintain a set of directories from which to
# load gems. If Bundler is loaded, let it determine what can be
# loaded. If it's not loaded, then use rubygems. But do this before
# loading any puppet code, so that our gem loading system is sane.
if not defined? ::Bundler
  begin
    require 'rubygems'
  rescue LoadError
  end
end

require 'puppet'
require 'puppet/util'
require "puppet/util/plugins"
require "puppet/util/rubygems"
require "puppet/util/limits"

module Puppet
  module Util
    # This is the main entry point for all puppet applications / faces; it
    # is basically where the bootstrapping process / lifecycle of an app
    # begins.
    class CommandLine
      include Puppet::Util::Limits

      OPTION_OR_MANIFEST_FILE = /^-|\.pp$|\.rb$/

      # @param zero [String] the name of the executable
      # @param argv [Array<String>] the arguments passed on the command line
      # @param stdin [IO] (unused)
      def initialize(zero = $0, argv = ARGV, stdin = STDIN)
        @command = File.basename(zero, '.rb')
        @argv = argv
        Puppet::Plugins.on_commandline_initialization(:command_line_object => self)
      end

      # @return [String] name of the subcommand is being executed
      # @api public
      def subcommand_name
        return @command if @command != 'puppet'

        if @argv.first =~ OPTION_OR_MANIFEST_FILE
          nil
        else
          @argv.first
        end
      end

      # @return [Array<String>] the command line arguments being passed to the subcommand
      # @api public
      def args
        return @argv if @command != 'puppet'

        if subcommand_name.nil?
          @argv
        else
          @argv[1..-1]
        end
      end

      # @api private
      # @deprecated
      def self.available_subcommands
        Puppet.deprecation_warning('Puppet::Util::CommandLine.available_subcommands is deprecated; please use Puppet::Application.available_application_names instead.')
        Puppet::Application.available_application_names
      end

      # available_subcommands was previously an instance method, not a class
      # method, and we have an unknown number of user-implemented applications
      # that depend on that behaviour.  Forwarding allows us to preserve a
      # backward compatible API. --daniel 2011-04-11
      # @api private
      # @deprecated
      def available_subcommands
        Puppet.deprecation_warning('Puppet::Util::CommandLine#available_subcommands is deprecated; please use Puppet::Application.available_application_names instead.')
        Puppet::Application.available_application_names
      end

      # Run the puppet subcommand. If the subcommand is determined to be an
      # external executable, this method will never return and the current
      # process will be replaced via {Kernel#exec}.
      #
      # @return [void]
      def execute
        Puppet::Util.exit_on_fail("intialize global default settings") do
          Puppet.initialize_settings(args)
        end

        setpriority(Puppet[:priority])

        find_subcommand.run
      end

      # @api private
      def external_subcommand
        Puppet::Util.which("puppet-#{subcommand_name}")
      end

      private

      def find_subcommand
        if subcommand_name.nil?
          NilSubcommand.new(self)
        elsif Puppet::Application.available_application_names.include?(subcommand_name)
          ApplicationSubcommand.new(subcommand_name, self)
        elsif path_to_subcommand = external_subcommand
          ExternalSubcommand.new(path_to_subcommand, self)
        else
          UnknownSubcommand.new(subcommand_name, self)
        end
      end

      # @api private
      class ApplicationSubcommand
        def initialize(subcommand_name, command_line)
          @subcommand_name = subcommand_name
          @command_line = command_line
        end

        def run
          # For most applications, we want to be able to load code from the modulepath,
          # such as apply, describe, resource, and faces.
          # For agent, we only want to load pluginsync'ed code from libdir.
          # For master, we shouldn't ever be loading per-enviroment code into the master's
          # ruby process, but that requires fixing (#17210, #12173, #8750). So for now
          # we try to restrict to only code that can be autoloaded from the node's
          # environment.
          if @subcommand_name != 'master' and @subcommand_name != 'agent'
            Puppet::Node::Environment.new.each_plugin_directory do |dir|
              $LOAD_PATH << dir unless $LOAD_PATH.include?(dir)
            end
          end

          app = Puppet::Application.find(@subcommand_name).new(@command_line)
          Puppet::Plugins.on_application_initialization(:application_object => @command_line)

          app.run
        end
      end

      # @api private
      class ExternalSubcommand
        def initialize(path_to_subcommand, command_line)
          @path_to_subcommand = path_to_subcommand
          @command_line = command_line
        end

        def run
          Kernel.exec(@path_to_subcommand, *@command_line.args)
        end
      end

      # @api private
      class NilSubcommand
        def initialize(command_line)
          @command_line = command_line
        end

        def run
          if @command_line.args.include? "--version" or @command_line.args.include? "-V"
            puts Puppet.version
          else
            puts "See 'puppet help' for help on available puppet subcommands"
          end
        end
      end

      # @api private
      class UnknownSubcommand < NilSubcommand
        def initialize(subcommand_name, command_line)
          @subcommand_name = subcommand_name
          super(command_line)
        end

        def run
          puts "Error: Unknown Puppet subcommand '#{@subcommand_name}'"
          super
        end
      end
    end
  end
end
