module Puppet::ModuleTool
  module Applications
    class Uninstaller < Application
      include Puppet::ModuleTool::Errors

      def initialize(name, options)
        @name        = name
        @options     = options
        @errors      = Hash.new {|h, k| h[k] = {}}
        @unfiltered  = []
        @installed   = []
        @suggestions = []
        @environment = Puppet::Node::Environment.new(options[:environment])
      end

      def run
        results = {
          :module_name       => @name,
          :requested_version => @version,
        }

        begin
          find_installed_module
          validate_module
          FileUtils.rm_rf(@installed.first.path, :secure => true)

          results[:affected_modules] = @installed
          results[:result] = :success
        rescue ModuleToolError => err
          results[:error] = {
            :oneline   => err.message,
            :multiline => err.multiline,
          }
        rescue => e
          results[:error] = {
            :oneline => e.message,
            :multiline => e.respond_to?(:multiline) ? e.multiline : [e.to_s, e.backtrace].join("\n")
          }
        ensure
          results[:result] ||= :failure
        end

        results
      end

      private

      def find_installed_module
        @environment.modules_by_path.values.flatten.each do |mod|
          mod_name = (mod.forge_name || mod.name).gsub('/', '-')
          if mod_name == @name
            @unfiltered << {
              :name    => mod_name,
              :version => mod.version,
              :path    => mod.modulepath,
            }
            if @options[:version] && mod.version
              next unless SemVer[@options[:version]].include?(SemVer.new(mod.version))
            end
            @installed << mod
          elsif mod_name =~ /#{@name}/
            @suggestions << mod_name
          end
        end

        if @installed.length > 1
          raise MultipleInstalledError,
            :action            => :uninstall,
            :module_name       => @name,
            :installed_modules => @installed.sort_by { |mod| @environment.modulepath.index(mod.modulepath) }
        elsif @installed.empty?
          if @unfiltered.empty?
            raise NotInstalledError,
              :action      => :uninstall,
              :suggestions => @suggestions,
              :module_name => @name
          else
            raise NoVersionMatchesError,
              :installed_modules => @unfiltered.sort_by { |mod| @environment.modulepath.index(mod[:path]) },
              :version_range     => @options[:version],
              :module_name       => @name
          end
        end
      end

      def validate_module
        mod = @installed.first

        if !@options[:force] && mod.has_metadata? && mod.has_local_changes?
          raise LocalChangesError,
            :action            => :uninstall,
            :module_name       => (mod.forge_name || mod.name).gsub('/', '-'),
            :requested_version => @options[:version],
            :installed_version => mod.version
        end

        if !@options[:force] && !mod.required_by.empty?
          raise ModuleIsRequiredError,
            :module_name       => (mod.forge_name || mod.name).gsub('/', '-'),
            :required_by       => mod.required_by,
            :requested_version => @options[:version],
            :installed_version => mod.version
        end
      end
    end
  end
end
