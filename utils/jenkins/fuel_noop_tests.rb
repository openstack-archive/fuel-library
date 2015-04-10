#!/usr/bin/env ruby

require 'rubygems'
require 'find'
require 'optparse'

module NoopTests
  def self.workspace
    workspace = ENV['WORKSPACE']
    unless workspace
      workspace = '/tmp/noop'
      Dir.mkdir workspace
    end
    unless File.directory? workspace
      raise "Workspace '#{workspace}' is not a directory!"
    end
    workspace
  end

  def self.options
    return @options if @options
    @options = {}
    optparse = OptionParser.new do|opts|
      opts.on('-d', '--debug', 'Show debug') do
        @options[:debug] = true
      end
      opts.on('-b', '--bundle', 'Use bundle to setup environment') do
        @options[:bundle] = true
      end
      opts.on('-m', '--missing', 'Find missing spec files') do
        @options[:missing_specs] = true
      end
      opts.on('-g', '--glob', 'Run specs with glob instead if individually') do
        @options[:run_glob] = true
      end
      opts.on('-s', '--specs SPECS', 'Run only these specs') do |specs|
        break unless specs
        @options[:filter_specs] = specs.split(',').map { |s| s.strip }
      end
      opts.on('-y', '--yamls YAMLS', 'Run only these yamls') do |yamls|
        break unless yamls
        @options[:filter_yamls] = yamls.split(',').map { |s| s.strip }
      end
      opts.on('-e', '--examples STRING', 'Run only these exemples') do |examples|
        break unless examples
        @options[:filter_examples] = examples.split(',').map { |s| s.strip }
      end
    end
    optparse.parse!
    @options
  end

  GLOBALS_SPEC = '010_globals_spec.rb'
  RSPEC_OPTIONS = '--format documentation --color --backtrace'
  ASTUTE_YAML_VAR = 'astute_filename'
  BUNDLE_DIR = '.bundled_gems'
  BUNDLE_VAR = 'GEM_HOME'
  GLOBALS_PREFIX = 'globals_yaml_for_'
  PUPPET_GEM_VERSION = '~> 3.4.0'
  ##

  def self.noop_tests_directory
    return @noop_tests_directory if @noop_tests_directory
    @noop_tests_directory = File.expand_path File.absolute_path File.join File.dirname(__FILE__), '..', '..', 'tests', 'noop'
  end

  def self.inside_noop_tests_directory
    current_directory = Dir.pwd
    Dir.chdir noop_tests_directory
    result = yield
    Dir.chdir current_directory if current_directory
    result
  end

  def self.astute_yaml_directory
    File.join noop_tests_directory, 'astute.yaml'
  end

  def self.test_spec_directory
    File.join noop_tests_directory, 'spec', 'hosts'
  end

  def self.modular_tasks_directory
    File.expand_path File.join File.dirname(__FILE__), '..', '..', 'deployment', 'puppet', 'osnailyfacter', 'modular'
  end

  ##

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

  def self.astute_yaml_files
    files = []
    Dir.new(astute_yaml_directory).each do |file|
      next if file.start_with? GLOBALS_PREFIX
      next unless file.end_with? '.yaml'
      files << file
    end
    files
  end

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

  ##

  def self.puppet_tasks_without_specs
    tasks = []
    modular_puppet_task_files.each do |task|
      spec = task.gsub '.pp', '_spec.rb'
      spec_path = File.join test_spec_directory, spec
      tasks << task unless File.exist? spec_path
    end
    tasks
  end

  def self.spec_path(spec)
    "'#{File.join test_spec_directory, spec}'"
  end

  def self.debug(msg)
    puts msg if options[:debug]
  end

  def self.rspec(spec)
    inside_noop_tests_directory do
      command = "rspec #{RSPEC_OPTIONS} #{spec}"
      command = 'bundle exec ' + command if options[:bundle]
      if options[:filter_examples]
        options[:filter_examples].each do |example|
          command = command + " -e #{example}"
        end
      end
      debug "RUN: #{command}"
      system command
      $?.exitstatus == 0
    end
  end

  def self.rspec_glob_all
    rspec '-P spec/hosts/*/*_spec.rb'
  end

  def self.globals(astute_yaml)
    globals_file = File.join astute_yaml_directory, GLOBALS_PREFIX + astute_yaml
    return true if File.file? globals_file
    rspec spec_path(GLOBALS_SPEC)
  end

  ##

  def self.filter_specs(spec)
    return true unless options[:filter_specs]
    options[:filter_specs].include? spec
  end

  def self.filter_yamls(yaml)
    return true unless options[:filter_yamls]
    options[:filter_yamls].map { |y| y.gsub('.yaml', '') }.include? yaml.gsub('.yaml', '')
  end

  def self.for_every_astute_yaml
    prepare_bundle if options[:bundle]
    results = {}
    astute_yaml_files.each do |astute_yaml|
      next unless filter_yamls astute_yaml
      ENV[ASTUTE_YAML_VAR] = astute_yaml
      debug "YAML: '#{astute_yaml}'"
      globals astute_yaml
      results[astute_yaml] = yield
    end
    results
  end

  def self.run_all_specs
    results = {}
    noop_spec_files.each do |spec|
      next if spec == GLOBALS_SPEC
      next unless filter_specs spec
      debug "SPEC: '#{spec}'"
      results[spec] = rspec spec_path(spec)
    end
    results
  end

  def self.prepare_bundle
    ENV['PUPPET_GEM_VERSION'] = PUPPET_GEM_VERSION unless ENV['PUPPET_GEM_VERSION']
    inside_noop_tests_directory do
      `bundle --version`
      raise 'Bundle is not installed!' if $?.exitstatus != 0
      ENV[BUNDLE_VAR] = File.join workspace, BUNDLE_DIR
      system 'bundle update'
      raise 'Could not prepare bundle environment!' if $?.exitstatus != 0
    end
  end

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

  def self.show_results_full(results)
    results.each do |astute_yaml, spec_results|
      puts "-> #{astute_yaml}"
      max_spec_length = spec_results.keys.inject(0) { |ml, key| key = key.to_s; ml = key.size if key.size > ml; ml }
      spec_results.each do |spec, success|
        puts "  * #{spec.ljust max_spec_length} #{status_string success}"
      end
    end
  end

  def self.show_results_glob(results)
    results.each do |astute_yaml, spec_results|
      puts "* #{astute_yaml} #{status_string spec_results}"
    end
  end

  def self.main
    result = for_every_astute_yaml do
      if options[:run_glob]
        rspec_glob_all
      else
        run_all_specs
      end
    end

    if options[:run_glob]
      show_results_glob result
    else
      show_results_full result
    end

    if options[:missing_specs]
      puts "Missing specs for tasks: #{puppet_tasks_without_specs.join ', '}"
    end
  end

end


NoopTests.main if __FILE__ == $0

