#!/usr/bin/env ruby

# Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

require 'rubygems'
require 'find'
require 'optparse'

module NoopTests
  GLOBALS_SPEC = 'globals/globals_spec.rb'
  RSPEC_OPTIONS = '--format documentation --color --tty --backtrace'
  ASTUTE_YAML_VAR = 'SPEC_ASTUTE_FILE_NAME'
  BUNDLE_DIR = '.bundled_gems'
  BUNDLE_VAR = 'GEM_HOME'
  PUPPET_GEM_VERSION = '~> 3.8.0'
  TEST_LIBRARY_DIR = 'spec/hosts'
  GLOBALS_YAML_FOLDER = 'globals'
  FIXTURES_YAML_DIR_DEFAULT = './tests/noop/spec/fixtures/modules/fuel-noop-fixtures/astute.yaml'

  def self.options
    return @options if @options
    @options = {}
    # defaults
    @options[:astute_yaml_dir] = FIXTURES_YAML_DIR_DEFAULT

    optparse = OptionParser.new do|opts|
      opts.separator 'Main options:'
      opts.on('-b', '--bundle', 'Use bundle to setup environment') do
        @options[:bundle] = true
      end
      opts.on('-m', '--missing', 'Find missing spec files') do
        @options[:missing_specs] = true
      end
      opts.on('-i', '--individually', 'Run each spec individually') do
        @options[:run_individually] = true
      end
      opts.on('-a', '--astute_yaml_dir DIR', 'Path to astute_yaml folder') do |dir|
        @options[:astute_yaml_dir] = dir
        ENV['SPEC_YAML_DIR'] = dir
      end
      opts.on('-Y', '--list_yamls', 'List all astute yaml files') do
        @options[:list_yamls] = true
      end
      opts.on('-S', '--list_specs', 'List all noop spec files') do
        @options[:list_specs] = true
      end
      opts.on('-g', '--skip_globals', "Don't run 'globals' task") do
        @options[:skip_globals] = true
      end
      opts.on('-A', '--failed_log FILE', 'Log failed specs and yamls to this file') do |file|
        @options[:failed_log] = file
      end
      opts.on('-E', '--run_failed_log FILE', 'Run only failed specs and yamls from the failed log') do |file|
        @options[:run_failed_log] = file
      end
      opts.separator 'Filter options:'
      opts.on('-s', '--specs SPEC1,SPEC2', Array, 'Run only these specs. Example: "hosts/hosts_spec.rb"') do |specs|
        specs = specs.map do |spec|
          spec.strip!
          spec.gsub! '.pp', '' if spec.end_with? '.pp'
          spec += '_spec.rb' unless spec.end_with? '_spec.rb'
          spec
        end
        @options[:filter_specs] = specs
      end
      opts.on('-y', '--yamls YAML1,YAML2', Array, 'Run only these yamls. Example: "novanet-primary-controller.yaml"') do |yamls|
        @options[:filter_yamls] = yamls
      end
      opts.on('-e', '--examples STR1,STR2', Array, 'Run only these exemples. Example: "should compile"') do |examples|
        @options[:filter_examples] = examples
      end
      opts.separator 'Debug options:'
      opts.on('-c', '--console', 'Run PRY console') do
        @options[:console] = true
      end
      opts.on('-d', '--debug', 'Show debug') do
        @options[:debug] = true
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
        @options[:puppet_logs_dir] = dir
      end
      opts.on('-u', '--update-librarian-puppet', 'Run librarian-puppet update in the deployment directory prior to testing') do
        @options[:update_librarian_puppet] = true
      end
      opts.on('-r', '--reset-librarian-puppet', 'Reset puppet modules to librarian versions in the deployment directory prior to testing') do
        @options[:reset_librarian_puppet] = true
      end

    end
    optparse.parse!
    @options
  end

  # PATHS #

  # workspace directory where gem bundle will be created
  # is passed from Jenkins or default value is used
  # @@return [String]
  def self.workspace
    workspace = ENV['WORKSPACE']
    unless workspace
      workspace = '/tmp/noop'
      Dir.mkdir workspace unless File.directory? workspace
    end
    unless File.directory? workspace
      raise "Workspace '#{workspace}' is not a directory!"
    end
    workspace
  end

  # the root directory of noop tests
  # @return [String]
  def self.noop_tests_directory
    return @noop_tests_directory if @noop_tests_directory
    @noop_tests_directory = File.expand_path File.absolute_path File.join File.dirname(__FILE__), '..', '..', 'tests', 'noop'
  end

  # the folder where astute yaml files are found
  # can be overridden by options
  # @return [String]
  def self.astute_yaml_directory
    return options[:astute_yaml_dir] if options[:astute_yaml_dir] and File.directory? options[:astute_yaml_dir]
    File.join noop_tests_directory, 'astute.yaml'
  end

  # the directory where actual tests library is found
  # @return [String]
  def self.test_spec_directory
    File.join noop_tests_directory, TEST_LIBRARY_DIR
  end

  # the directory where the library of modular tasks can be found
  # @return [String]
  def self.modular_tasks_directory
    File.expand_path File.join File.dirname(__FILE__), '..', '..', 'deployment', 'puppet', 'osnailyfacter', 'modular'
  end

  # the base directory that houses all the puppet module directory
  # @return [String]
  def self.deployment_directory
    File.expand_path File.join File.dirname(__FILE__), '..', '..', 'deployment'
  end

  # LISTERS #

  # find all modular task files
  # @return [Array<String>]
  def self.modular_puppet_task_files
    files = []
    Find.find(modular_tasks_directory) do |file|
      next unless File.file? file
      next unless file.end_with? '.pp'
      file.gsub! modular_tasks_directory + '/', ''
      files << file
    end
    files
  end

  # find all astute yaml files
  # @return [Array<String>]
  def self.astute_yaml_files
    files = []
    Dir.entries(astute_yaml_directory).each do |file|
      next unless File.file? File.join astute_yaml_directory, file
      next unless file.end_with? '.yaml'
      files << file
    end
    files
  end

  # find all noop spec files
  # @return [Array<String>]
  def self.noop_spec_files
    files = []
    Find.find(test_spec_directory) do |file|
      next unless File.file? file
      next unless file.end_with? '_spec.rb'
      file.gsub! test_spec_directory + '/', ''
      files << file
    end
    files
  end

  # ACTIONS #

  # run the code block inside the tests directory
  # and then return back
  def self.inside_noop_tests_directory
    current_directory = Dir.pwd
    Dir.chdir noop_tests_directory
    result = yield
    Dir.chdir current_directory if current_directory
    result
  end

  # run the clode block inside the deployment driectory
  # and then return back
  def self.inside_deployment_directory
    current_directory = Dir.pwd
    Dir.chdir deployment_directory
    result = yield
    Dir.chdir current_directory if current_directory
    result
  end

  # find all modular tasks that have no corresponding specs
  # @return [Array<String>]
  def self.puppet_tasks_without_specs
    tasks = []
    modular_puppet_task_files.each do |task|
      spec = task.gsub '.pp', '_spec.rb'
      spec_path = File.join test_spec_directory, spec
      tasks << task unless File.exist? spec_path
    end
    tasks
  end

  # append relative path prefix to a spec name
  # @param [String] spec Spec name
  # @return [String]
  def self.spec_path(spec)
    "'#{File.join TEST_LIBRARY_DIR, spec}'"
  end

  # run the rake spec_prep to get fixtures
  # return: success
  # @return success
  def self.rake_prep
    inside_noop_tests_directory do
      command_prep = "rake spec_prep"
      command_prep = 'bundle exec ' + command_prep if options[:bundle]
      debug " RUN: #{command_prep}"
      system command_prep
      $?.exitstatus == 0
    end
  end

  # run the rspec commands with some options
  # return: [ success, report ]
  # @param [String] spec Spec file or pattern
  # @return [Array<TrueClass,FalseClass,NilClass>] success and empty report array
  def self.rspec(spec)
    inside_noop_tests_directory do
      command = "rspec #{RSPEC_OPTIONS} #{spec}"
      command = 'bundle exec ' + command if options[:bundle]
      if options[:filter_examples]
        options[:filter_examples].each do |example|
          command = command + " -e #{example}"
        end
      end
      if options[:puppet_logs_dir]
        command = command + " --deprecation-out #{File.join options[:puppet_logs_dir], 'deprecations.log'}"
      end
      debug "RUN: #{command}"
      system command
      [ $?.exitstatus == 0, nil ]
    end
  end

  # run all specs together using pattern
  # return: [ success, report ]
  # @return [Array<TrueClass,FalseClass,NilClass>] success and empty report array
  def self.run_all_specs
    include_prefix = '--pattern'
    exclude_prefix = '--exclude-pattern'
    exclude_pattern = "#{exclude_prefix} #{spec_path GLOBALS_SPEC}"
    if options[:filter_specs]
      include_pattern = "#{include_prefix} #{options[:filter_specs].map { |s| spec_path s }.join ','}"
    else
      include_pattern = "#{include_prefix} #{spec_path '**/*_spec.rb'}"
    end

    rspec "#{exclude_pattern} #{include_pattern}"
  end

  # run the globals task for the given yaml file
  # @param [String] astute_yaml YAML file
  def self.globals(astute_yaml)
    return if options[:skip_globals]
    globals_file = File.join astute_yaml_directory, GLOBALS_YAML_FOLDER, astute_yaml
    if File.file? globals_file
      begin
        File.unlink globals_file
        debug "Globals file was removed: '#{globals_file}'"
      rescue => e
        debug "Could not remove globals file: '#{globals_file}'! (#{e.message})"
      end
    end
    rspec spec_path(GLOBALS_SPEC)
  end

  # output a debug line is debug is enabled
  # @param [String] msg The message line
  def self.debug(msg)
    puts msg if options[:debug]
  end

  # decide if this spec should be included
  # @param [String] spec Spec file
  # @return [TrueClass,FalseClass]
  def self.filter_specs(spec)
    return false if spec == GLOBALS_SPEC
    return true unless options[:filter_specs]
    options[:filter_specs].include? spec
  end

  # decide if this yaml should be included
  # @param [String] yaml Yaml file
  # @return [TrueClass,FalseClass]
  def self.filter_yamls(yaml)
    return true unless options[:filter_yamls]
    options[:filter_yamls].map { |y| y.gsub('.yaml', '') }.include? yaml.gsub('.yaml', '')
  end

  # run the code block for every astute yaml file
  # return [ global success, Hash of reports for every yaml ]
  # @return [Array<TrueClass,FalseClass,Hash>]
  def self.for_every_astute_yaml
    prepare_bundle if options[:bundle]
    results = {}
    errors = 0
    astute_yaml_files.each do |astute_yaml|
      next unless filter_yamls astute_yaml
      ENV[ASTUTE_YAML_VAR] = astute_yaml
      debug "=== YAML: '#{astute_yaml}' ==="
      globals astute_yaml
      success, report = yield
      errors += 1 unless success
      results[astute_yaml] = {
          :success => success,
          :report => report,
      }
    end
    [ errors == 0, results ]
  end

  # run every spec file individually
  # return report for every spec
  # return [ global success, Hash of reports for every spec ]
  # @return [Array<TrueClass,FalseClass,Hash>]
  def self.run_all_specs_individually
    results = {}
    errors = 0
    noop_spec_files.each do |spec|
      next if spec == GLOBALS_SPEC
      next unless filter_specs spec
      debug "--- SPEC: '#{spec}' ---"
      success, report = rspec spec_path(spec)
      errors += 1 unless success
      results[spec] = {
          :success => success,
          :report => report,
      }
    end
    [ errors == 0, results ]
  end

  # directly run the specific spec with a specific yaml
  # @param yaml [String] yaml file name
  # @param spec [String] spec name
  # @return [Array] success and results array
  def self.run_yaml_and_spec_pair(yaml, spec=nil)
    ENV[ASTUTE_YAML_VAR] = yaml
    globals yaml
    rspec spec_path(spec)
  end

  # setup the bundle directory
  def self.prepare_bundle
    ENV['PUPPET_GEM_VERSION'] = PUPPET_GEM_VERSION unless ENV['PUPPET_GEM_VERSION']
    inside_noop_tests_directory do
      `bundle --version`
      raise 'Bundle is not installed!' if $?.exitstatus != 0
      ENV[BUNDLE_VAR] = File.join workspace, BUNDLE_DIR
      system 'bundle install'
      system 'bundle update'
      raise 'Could not prepare bundle environment!' if $?.exitstatus != 0
    end
  end

  # run librarian-puppet to fetch modules as necessary
  def self.prepare_library
    # these are needed to ensure we have the correctly bundle
    ENV['PUPPET_GEM_VERSION'] = PUPPET_GEM_VERSION unless ENV['PUPPET_GEM_VERSION']
    ENV['BUNDLE_DIR'] = File.join workspace, BUNDLE_DIR
    command = './update_modules.sh -v'
    # pass the bundle parameter to update_modules if specified for this script
    command = command + ' -b' if options[:bundle]
    # pass the reset parameter to update_modules if specified for this script
    command = command + ' -r' if options[:reset_librarian_puppet]

    inside_deployment_directory do
      puts "-> Starting update_modules script"
      system command
      raise 'Unable to update upstream puppet modules using librarian-puppet' if $?.exitstatus != 0
      puts "-> Finished update_modules script"
    end
  end

  # add color codes to a line
  # @param [Integer] code Color code
  # @param [String] string Text string
  def self.color(code, string)
    "\033[#{code}m#{string}\033[0m"
  end

  def self.status_string(success)
    if success
      color 32, 'OK'
    else
      color 31, 'FAIL'
    end
  end

  # calculate the maximum length of the hash keys
  # used to align columns
  # @param [Hash]
  # @return [Integer]
  def self.max_key_length(hash)
    hash.keys.inject(0) do |ml, key|
      key = key.to_s
      ml = key.size if key.size > ml
      ml
    end
  end

  def self.save_failed_log(results)
    return unless options[:failed_log]
    File.open(options[:failed_log], 'w') do |file|
      results.each do |astute_yaml, yaml_result|
        if yaml_result[:report].is_a? Hash
          yaml_result.fetch(:report, {}).each do |spec, spec_result|
            file.puts "#{astute_yaml} #{spec}" unless spec_result[:success]
          end
        else
          file.puts astute_yaml unless yaml_result[:success]
        end
      end
    end
  end

  # run specs and yamls found in the failed log file
  # it can be either just a list of yaml names
  # or yaml name and spec name speparated by space
  # log file can be generated by -A options or written manually
  # @param log_file [String] path to the failed log file
  # @return [Hash] results structure
  def self.run_failed_log(log_file)
    raise "Unable to read failed log file: '#{log_file}'!" unless File.readable? log_file
    log = File.read log_file
    results = {}
    errors = 0
    log.split("\n").each do |line|
      line_array = line.strip.split
      yaml = line_array[0]
      spec = line_array[1]
      next unless yaml
      debug "=== YAML: '#{yaml}' ==="
      debug "--- SPEC: '#{spec}' ---" if spec
      unless results[yaml]
         results[yaml] = {
             :success => true,
             :report => {},
         }
      end
      success, report = run_yaml_and_spec_pair yaml, spec
      errors += 1 unless success
      spec_result = {
          :success => success,
          :report => report,
      }
      if spec
        results[yaml][:sucess] = false unless spec_result[:success]
        results[yaml][:report][spec] = {} unless results[yaml][:report]
        results[yaml][:report][spec] = spec_result
      else
        results[yaml] = spec_result
      end
    end
    [ errors == 0, results ]
  end

  # output the test results
  # @param [Hash]
  def self.show_results(results)
    max_astute_yaml_length = max_key_length results
    results.each do |astute_yaml, yaml_result|
      puts "-> #{astute_yaml.ljust max_astute_yaml_length} #{status_string yaml_result[:success]}"
      if yaml_result[:report].is_a? Hash
        max_spec_length = max_key_length yaml_result[:report]
        yaml_result[:report].each do |spec, spec_result|
          puts "  * #{spec.ljust max_spec_length} #{status_string spec_result[:success]}"
        end
      end
    end
  end

  # the main function
  def self.main
    if options[:console]
      require 'pry'
      self.pry
      exit 0
    end

    # ensure fixtures
    prepare_bundle if options[:bundle]
    rake_prep

    if options[:missing_specs]
      missing_specs = puppet_tasks_without_specs
      if missing_specs.any?
        puts color(31, "Missing specs for tasks: #{missing_specs.join ', '}")
        exit missing_specs.length
      end
    end

    if options[:list_yamls]
      astute_yaml_files.each do |file|
        puts file
      end
      exit 0
    end

    if options[:list_specs]
      noop_spec_files.each do |file|
        puts file
      end
      exit 0
    end

    if options[:update_librarian_puppet]
      prepare_library
    end

    # failed log replay
    if options[:run_failed_log]
      success, result = run_failed_log options[:run_failed_log]
      show_results result
      save_failed_log result
      exit 1 unless success
      exit 0
    end

    debug "Spec filter: #{options[:filter_specs]}" if options[:filter_specs]
    debug "Yaml filter: #{options[:filter_yamls]}" if options[:filter_yamls]

    success, result = for_every_astute_yaml do
      if options[:run_individually]
        run_all_specs_individually
      else
        run_all_specs
      end
    end

    show_results result
    save_failed_log result

    exit 1 unless success
    exit 0
  end

end

NoopTests.main if __FILE__ == $0

