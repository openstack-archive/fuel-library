class Noop
  module Overrides
    def hiera_config
      if ENV['SPEC_PUPPET_DEBUG']
        logger = 'console'
      else
        logger = 'noop'
      end
      {
          :backends => [
              'yaml',
          ],
          :yaml => {
              :datadir => hiera_data_path,
          },
          :hierarchy => hiera_config_hierarhy,
          :logger => logger,
          :merge_behavior => :deeper,
      }
    end

    def hiera_config_hierarhy
      elements = []
      elements << hiera_task_override if hiera_task_override_present?
      elements << hiera_data_globals
      elements << hiera_data_astute
      elements
    end

    def hiera_object
      # hiera may be unstable with mnemoization object
      # return @hiera_object if @hiera_object
      @hiera_object = Hiera.new(:config => hiera_config)
      Hiera.logger = hiera_config[:logger]
      @hiera_object
    end

    def hiera(key, default = nil, resolution_type = :priority)
      key = key.to_s
      # def lookup(key, default, scope, order_override=nil, resolution_type=:priority)
      hiera_object.lookup key, default, {}, nil, resolution_type
    end

    def hiera_hash(key, default = nil)
      hiera key, default, :hash
    end

    def hiera_array(key, default = nil)
      hiera key, default, :array
    end

    def hiera_structure(key, default = nil, separator = '/', resolution_type = :priority)
      path_lookup = lambda do |data, path, default_value|
        break default_value unless data
        break data unless path.is_a? Array and path.any?
        break default_value unless data.is_a? Hash or data.is_a? Array

        key = path.shift
        if data.is_a? Array
          begin
            key = Integer key
          rescue ArgumentError
            break default_value
          end
        end
        path_lookup.call data[key], path, default_value
      end

      path = key.split separator
      key = path.shift
      data = hiera key, nil, resolution_type
      path_lookup.call data, path, default
    end

    ## Overrides ##

    def hiera_puppet_override
      class << HieraPuppet
        def hiera
          Noop.hiera_object
        end
      end

      class << Hiera::Config
        def load(source)
          @config = Noop.hiera_config
        end

        def yaml_load_file(source)
          @config = Noop.hiera_config
        end

        def []=(key, value)
          @config[key] = value
        end

        attr_accessor :config
      end
    end

    def puppet_debug_override
      Puppet::Util::Log.level = :debug
      Puppet::Util::Log.newdestination(:console)
    end

    def puppet_resource_scope_override
      Puppet::Parser::Resource.module_eval do
        def initialize(*args)
          raise ArgumentError, "Resources require a hash as last argument" unless args.last.is_a? Hash
          raise ArgumentError, "Resources require a scope" unless args.last[:scope]
          super
          Noop.puppet_scope = scope
          @source ||= scope.source
        end
      end
    end

    # These settings are pullled from the Puppet TestHelper
    # (See Puppet::Test::TestHelper.initialize_settings_before_each)
    # These items used to be setup in puppet 3.4 but were moved to before tests
    # which breaks our testing framework because we attempt to call
    # PuppetlabsSpec::PuppetInternals.scope and
    # Puppet::Parser::Function.autoload.load prior to the testing being run.
    # This results in an rspec failure so we need to initialize the basic
    # settings up front to prevent issues with test framework. See PUP-5601
    def puppet_default_settings
        Puppet.settings.initialize_app_defaults({
          :logdir       => '/dev/null',
          :confdir      => '/dev/null',
          :vardir       => '/dev/null',
          :rundir       => '/dev/null',
          :hiera_config => '/dev/null',
        })
    end

    def setup_overrides
      puppet_default_settings
      hiera_puppet_override
      puppet_debug_override if ENV['SPEC_PUPPET_DEBUG']
      puppet_resource_scope_override
    end

    # shortcuts

    def fqdn
      fqdn = hiera 'fqdn'
      raise 'Unable to get FQDN from Hiera!' unless fqdn
      fqdn
    end

    def role
      hiera 'role'
    end

    def hostname
      self.fqdn.split('.').first
    end

    # remove unused code, related to nodes list
    # def node_hash
    #   hiera('nodes').find { |node| node['fqdn'] == fqdn } || {}
    # end

  end
  extend Overrides
end
