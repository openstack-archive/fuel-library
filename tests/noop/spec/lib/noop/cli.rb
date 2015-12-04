require 'ostruct'
require 'colorize'
require 'open3'
require 'optparse'
require 'parallel'

class Noop
  module CLI

    RSPEC_OPTIONS = %w(-f doc -c --tty -b)
    ASTUTE_YAML_VAR = 'SPEC_ASTUTE_FILE_NAME'
    GLOBALS_SPEC = 'globals/globals_spec.rb'
    ASTUTE_YAML_VAR = 'SPEC_ASTUTE_FILE_NAME'

    def options
      return @options if @options
      @options = OpenStruct.new

      optparse = OptionParser.new do|opts|
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
          @options.filter_yamls = yamls
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
      @options
    end

    # run the code block inside the tests directory
    # and then return back
    def inside_noop_root_path
      current_directory = Dir.pwd
      Dir.chdir noop_root_path
      result = yield
      Dir.chdir current_directory if current_directory
      result
    end

    # run the clode block inside the deployment driectory
    # and then return back
    def inside_deployment_path
      current_directory = Dir.pwd
      Dir.chdir deployment_path
      result = yield
      Dir.chdir current_directory if current_directory
      result
    end

    # find all modular tasks that have no corresponding specs
    # @return [Array<String>]
    def puppet_tasks_without_specs
      tasks = []
      modular_task_files.each do |task|
        spec = task.gsub '.pp', '_spec.rb'
        spec_path = File.join spec_hosts_path, spec
        tasks << task unless File.exist? spec_path
      end
      tasks
    end

    def run(yaml, *args)
      env = { ASTUTE_YAML_VAR => yaml }
      if parallel_enabled?
        *out = Open3.capture2e *args
        out.last.exitstatus
      else
        system env, *args.flatten
        $?.exitstatus
      end
    end

    # decide if this spec should be included
    # @param [String] spec Spec file
    # @return [TrueClass,FalseClass]
    def filter_specs(spec)
      return false if spec == GLOBALS_SPEC
      return true unless options.filter_specs
      options.filter_specs.include? spec
    end

    # decide if this yaml should be included
    # @param [String] yaml Yaml file
    # @return [TrueClass,FalseClass]
    def filter_yamls(yaml)
      return true unless options.filter_yamls
      options.filter_yamls.map { |y| y.gsub('.yaml', '') }.include? yaml.gsub('.yaml', '')
    end

    def parallel_enabled?
      options.parallel_run and options.parallel_run > 0
    end

    def proctitle=(value)
      return unless parallel_enabled?
      $0 = value
    end

    def proctitle
      return unless parallel_enabled?
      $0
    end

    def full_spec_path(spec)
      File.join spec_hosts_path, spec
    end

    def rspec(yaml, spec)
      inside_noop_root_path do
        command = ['rspec']
        command += RSPEC_OPTIONS unless parallel_enabled?
        command << spec
        command = %w(bundle exec) + command if options.bundle

        if options.filter_examples
          options.filter_examples.each do |example|
            command = command + ['-e', example]
          end
        end

        puts  "Run: #{command.flatten.join ' '} (#{yaml})"
        exit_code = run yaml, command
        puts  "Finish: #{command.flatten.join ' '} (#{yaml}) [exit: #{exit_code}]"
        exit_code == 0
      end
    end

    def run_rspec_individually(yaml)
      parallel_results = Parallel.map(
          noop_spec_files,
          :in_threads => options.parallel_run
      ) do |spec|
        next if spec == GLOBALS_SPEC
        next unless filter_specs spec
        debug "Processing SPEC: '#{spec}'"
        success = rspec yaml, full_spec_path(spec)
        report = {
            :success => success,
            :spec => spec,
        }
        [spec, report]
      end
      report = {
          :success => true,
          :report => {},
          :yaml => yaml,
      }
      parallel_results.each do |spec, result|
        next unless spec and result
        report[:success] = false unless result[:success]
        report[:report][spec] = result
      end
      report
    end

    def run_rspec_with_pattern(yaml)
      include_prefix = '--pattern'
      exclude_prefix = '--exclude-pattern'

      exclude_pattern = [ exclude_prefix, full_spec_path(GLOBALS_SPEC) ]

      if options[:filter_specs]
        include_specs = options.filter_specs.map do |spec|
          full_spec_path(spec)
        end.join(',')
        include_pattern = [ include_prefix, include_specs ]
      else
        include_pattern = [ include_prefix,  full_spec_path('**/*_spec.rb') ]
      end

      rspec yaml, exclude_pattern + include_pattern
    end

    def astute_yaml_iteration
      # prepare_bundle if options.bundle
      self.proctitle = 'Noop tests Master'
      debug "Running Master process with pid: #{Process.pid}" if parallel_enabled?

      parallel_results = Parallel.map(
          astute_yaml_files,
          :in_processes => options.parallel_run
      ) do |astute_yaml|
        next unless filter_yamls astute_yaml
        debug "Start processing YAML: '#{astute_yaml}'"
        self.proctitle = "Noop tests for YAML: '#{astute_yaml}'"
        globals astute_yaml
        result = yield
        [ astute_yaml, result ]
      end

      report = {
          :success => true,
          :report => {},
      }
      parallel_results.each do |astute_yaml, result|
        next unless result
        report[:success] = false unless result[:success]
        report[:report][astute_yaml] = result
      end
      report
    end

  end
  extend CLI
end
