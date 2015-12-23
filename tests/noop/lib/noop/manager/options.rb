require 'optparse'
require 'ostruct'

module Noop
  class Manager

    # @return [OpenStruct]
    def options
      return @options if @options
      @options = OpenStruct.new

      optparse = OptionParser.new do |opts|
        opts.separator 'Main options:'
        opts.on('-b', '--bundle', 'Use bundle to setup environment') do
          @options.bundle = true
        end
        opts.on('-m', '--missing', 'Find missing spec files') do
          @options.missing_specs = true
        end
        opts.on('-i', '--individually', 'Run each spec individually') do
          @options.run_individually = true
        end
        opts.on('-j', '--jobs JOBS', 'Parallel run rapec jobs') do |jobs|
          @options.parallel_run = jobs.to_i
        end
        opts.on('-a', '--astute_yaml_dir DIR', 'Path to astute_yaml folder') do |dir|
          @options.astute_yaml_dir = dir
          ENV['SPEC_YAML_DIR'] = dir
        end
        opts.on('-Y', '--list_yamls', 'List all astute yaml files') do
          @options.list_yamls = true
        end
        opts.on('-S', '--list_specs', 'List all noop spec files') do
          @options.list_specs = true
        end
        opts.on('-g', '--skip_globals', "Don't run 'globals' task") do
          @options.skip_globals = true
        end
        opts.on('-A', '--failed_log FILE', 'Log failed specs and yamls to this file') do |file|
          @options.failed_log = file
        end
        opts.on('-E', '--run_failed_log FILE', 'Run only failed specs and yamls from the failed log') do |file|
          @options.run_failed_log = file
        end
        opts.separator 'Filter options:'
        opts.on('-s', '--specs SPEC1,SPEC2', Array, 'Run only these specs. Example: "hosts/hosts_spec.rb"') do |specs|
          specs = specs.map do |spec|
            spec.strip!
            spec.gsub! '.pp', '' if spec.end_with? '.pp'
            spec += '_spec.rb' unless spec.end_with? '_spec.rb'
            spec
          end
          @options.filter_specs = specs
        end
        opts.on('-y', '--yamls YAML1,YAML2', Array, 'Run only these yamls. Example: "novanet-primary-controller.yaml"') do |yamls|
          @options.filter_hiera = yamls
        end
        opts.on('-e', '--examples STR1,STR2', Array, 'Run only these exemples. Example: "should compile"') do |examples|
          @options.filter_examples = examples
        end
        opts.separator 'Debug options:'
        opts.on('-c', '--console', 'Run PRY console') do
          @options.console = true
        end
        opts.on('-d', '--debug', 'Show debug') do
          @options.debug = true
        end
        opts.separator 'Spec options:'
        opts.on('-F', '--file_resources DIR', 'Save file resources to this dir') do |dir|
          ENV['SPEC_SAVE_FILE_RESOURCES'] = dir
        end
        opts.on('-C', '--catalog_show', 'Show catalog debug output') do
          ENV['SPEC_CATALOG_SHOW'] = 'YES'
        end
        opts.on('-Q', '--catalog_save', 'Save catalog to the files instead of comparing them with the current catalogs') do
          ENV['SPEC_CATALOG_CHECK'] = 'save'
        end
        opts.on('-q', '--catalog_check', 'Check the saved catalog against the current one') do
          ENV['SPEC_CATALOG_CHECK'] = 'check'
        end
        opts.on('-G', '--spec_generate', 'Generate specs for catalogs') do
          ENV['SPEC_SPEC_GENERATE'] = 'YES'
        end
        opts.on('-T', '--spec_status', 'Show spec status blocks') do
          ENV['SPEC_SHOW_STATUS'] = 'YES'
        end
        opts.on('-O', '--spec_coverage', 'Show spec coverage statistics') do
          ENV['SPEC_COVERAGE'] = 'YES'
        end
        opts.on('-D', '--test_ubuntu', 'Run tests for Ubuntu facts') do
          ENV['SPEC_TEST_UBUNTU'] = 'YES'
        end
        opts.on('-R', '--test_centos', 'Run tests for CentOS facts') do
          ENV['SPEC_TEST_CENTOS'] = 'YES'
        end
        opts.on('-p', '--puppet_debug', 'Show Puppet debug messages') do
          ENV['SPEC_PUPPET_DEBUG'] = 'YES'
        end
        opts.on('-B', '--puppet_binary_files', 'Check if Puppet installs binary files') do
          ENV['SPEC_PUPPET_BINARY_FILES'] = 'YES'
        end
        opts.on('-L', '--puppet_logs_dir DIR', 'Save Puppet logs in this directory') do |dir|
          ENV['SPEC_PUPPET_LOGS_DIR'] = dir
          @options.puppet_logs_dir = dir
        end
        opts.on('-u', '--update-librarian-puppet', 'Run librarian-puppet update in the deployment directory prior to testing') do
          @options.update_librarian_puppet = true
        end
        opts.on('-r', '--reset-librarian-puppet', 'Reset puppet modules to librarian versions in the deployment directory prior to testing') do
          @options.reset_librarian_puppet = true
        end

      end
      optparse.parse!
      @options.parallel_run = 10
      @options.filter_specs = ['roles/controller_spec.rb', 'apache/apache_spec.rb']
      @options.filter_facts = ['ubuntu.yaml']
      # @options.filter_hiera = ['novanet-primary-controller.yaml']
      @options
    end

  end
end
