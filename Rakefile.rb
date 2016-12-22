require 'rake'
require 'open3'

##### Configuration

MODULES_DIR = 'deployment/puppet'
MODULES_IGNORE = %w(mellanox_openstack)
LINT_IGNORE = %w()
SPEC_IGNORE = %w()
VALIDATE_IGNORE = %w()
BUNDLER_IGNORE = %w()
DISABLE_RSPEC_FILE = './utils/jenkins/modules.disable_rspec'
DISABLE_LINT_FILE = './utils/jenkins/modules.disable_rake-lint'

def modules_ignore
  return ENV['SPEC_MODULES_IGNORE'].split if ENV['SPEC_MODULES_IGNORE']
  puppet_file_modules + MODULES_IGNORE
end

def lint_ignore
  return ENV['SPEC_LINT_IGNORE'].split if ENV['SPEC_LINT_IGNORE']
  disable_lint_modules + LINT_IGNORE
end

def spec_ignore
  return ENV['SPEC_SPEC_IGNORE'].split if ENV['SPEC_SPEC_IGNORE']
  disable_rspec_modules + SPEC_IGNORE
end

def validate_ignore
  return ENV['SPEC_VALIDATE_IGNORE'].split if ENV['SPEC_VALIDATE_IGNORE']
  VALIDATE_IGNORE
end

def bundler_ignore
  return ENV['SPEC_BUNDLER_IGNORE'].split if ENV['SPEC_BUNDLER_IGNORE']
  BUNDLER_IGNORE
end

def puppet_files
  %w(./deployment/puppet/openstack_tasks/Puppetfile ./deployment/Puppetfile)
end

def puppet_file_modules
  return $puppet_file_modules if $puppet_file_modules
  $puppet_file_modules = []
  puppet_files.each do |file|
    File.read(file).split("\n").each do |line|
      next if line =~ /^\s*#/
      if line =~ /^\s*mod\s*['"]+(\S+)['"]+,/
        puppet_file_modules << $1
      end
    end
  end
  $puppet_file_modules
end

def disable_rspec_modules
  return $disable_rspec_modules if $disable_rspec_modules
  $disable_rspec_modules = []
  return $disable_rspec_modules unless File.file? DISABLE_RSPEC_FILE
  File.read(DISABLE_RSPEC_FILE).split("\n").each do |line|
    next if line =~ /^\s*#/
    $disable_rspec_modules << line.chomp.strip
  end
  $disable_rspec_modules
end

def disable_lint_modules
  return $disable_lint_modules if $disable_lint_modules
  $disable_lint_modules = []
  return $disable_lint_modules unless File.file? DISABLE_LINT_FILE
  File.read(DISABLE_LINT_FILE).split("\n").each do |line|
    next if line =~ /^\s*#/
    $disable_lint_modules << line.chomp.strip
  end
  $disable_lint_modules
end

##### Interface

def output(message)
  puts message
end

def run(*cmd)
  puts "$ #{cmd.flatten.join ' '}"
  env = {}
  %w(BUNDLE_BIN_PATH BUNDLE_GEMFILE BUNDLE_ORIG_GEM_PATH BUNDLE_ORIG_PATH RUBYLIB RUBYOPT).each do |var|
    env.store var, nil
  end
  system env, *cmd
end

##### Library

def modules
  return [] unless File.directory? MODULES_DIR
  return $modules if $modules
  $modules = []
  Dir.entries(MODULES_DIR).each do |entry|
    next if %w(. ..).include? entry
    next if modules_ignore.include? entry
    path = File.join MODULES_DIR, entry
    next unless File.directory? path
    $modules << path
  end
  $modules
end

##### Actions

def remove_gemfile_lock(path)
  return if ENV['SPEC_KEEP_GEMFILE_LOCK']
  gemfile_lock_path = File.join path, 'Gemfile.lock'
  return unless File.file? gemfile_lock_path
  puts "Remove: #{gemfile_lock_path}"
  File.unlink gemfile_lock_path
end

def prepare_gem_bundle(path)
  Dir.chdir(path) do
    run 'bundle', 'install'
  end
end

def task_defined?(path, task)
  return false unless rakefile_present? path
  Dir.chdir(path) do
    run "rake -T  | grep -q '^rake #{task}\s*#'"
  end
end

def rakefile_present?(path)
  File.file? File.join path, 'Rakefile'
end

def gemfile_present?(path)
  File.file? File.join path, 'Gemfile'
end

def run_task(path, task)
  Dir.chdir(path) do
    run 'rake', task
  end
end

def run_task_if_defined(path, task)
  if task_defined? path, task
    run_task path, task
  else
    output red "There is no task: '#{task}' in the module: '#{path}' or the Rakefile is missing or not working!"
    nil
  end
end

def prepare_gem_bundle_if_present(path)
  if gemfile_present? path
    remove_gemfile_lock path
    prepare_gem_bundle path
  else
    output red "There is no Gemfile for the module: '#{path}'!"
    nil
  end
end

##### Reporting

def make_record(module_name, task, result)
  $report = {} unless $report.is_a? Hash
  $report[module_name] = {} unless $report[module_name].is_a? Hash
  $report[module_name][task] = result unless result.is_a? NilClass
end

def red(message)
  "\033[31m#{message}\033[0m"
end

def green(message)
  "\033[32m#{message}\033[0m"
end

def check_empty_report
  unless $report and $report.is_a? Hash and $report.values.any? do |tasks|
    next false unless tasks.is_a? Hash
    tasks.keys.any?
  end
    output red 'The report is empty! Did you actually run any tasks?'
    exit(2)
  end
end

def show_report
  longest_task_name = 0
  longest_module_name = 0
  $report.each do |module_name, tasks|
    next unless tasks.is_a? Hash and tasks.any?
    module_name_length = module_name.length
    longest_module_name = module_name_length if module_name_length > longest_module_name
    tasks.each do |task_name, _result|
      task_name_length = task_name.length
      longest_task_name = task_name_length if task_name_length > longest_task_name
    end
  end

  output '#' * 60

  $report.each do |module_name, tasks|
    next unless tasks.is_a? Hash and tasks.any?
    tasks.each do |task_name, result|
      status = result ? green('OK') : red('FAIL')
      output "#{module_name.ljust longest_module_name} : #{task_name.ljust longest_task_name} -> #{status}"
    end
  end

  output '#' * 60
end

def exit_with_error_code(check_tasks = [])
  check_tasks = [check_tasks] unless check_tasks.is_a? Array

  $report.each do |module_name, tasks|
    next unless tasks.is_a? Hash and tasks.any?
    tasks.each do |task_name, result|
      if check_tasks.any?
        next unless check_tasks.include? task_name
      end
      unless result
        output red "Task: '#{task_name}' of the module: '#{module_name}' have failed!"
        exit(1)
      end
    end
  end

  output green 'The test was successful!'
  exit(0)
end

##### Tasks

def make_run_task(path, module_name, task_name, tasks=[], dependencies=nil)
  title = "#{module_name}:#{task_name}"
  ignore = "#{task_name}_ignore".to_sym
  unless dependencies
    dependencies = ["#{module_name}:bundler"]
  end

  desc "Run the task: #{task_name} for the module: #{module_name}"
  task title => dependencies do
    begin
      if send(ignore).is_a? Array and send(ignore).include? module_name
        output green "Skip task: #{title}"
        next
      end
    rescue NameError
      nil
    end

    output green "Run task: #{title}"
    if block_given?
      result = yield path, task_name, module_name
    else
      result = run_task_if_defined path, task_name
    end
    make_record module_name, task_name, result
  end

  task_name_sym = task_name.to_sym
  tasks[task_name_sym] = [] unless tasks[task_name_sym].is_a? Array
  tasks[module_name] = [] unless tasks[module_name].is_a? Array
  tasks[task_name_sym] << title
  tasks[module_name] << title
end

def make_bundler_task(path, module_name, tasks=[])
  task_name = 'bundler'
  make_run_task path, module_name, task_name, tasks, [] do
    prepare_gem_bundle_if_present path
  end
end

tasks = {}

modules.each do |path|
  module_name = File.basename path
  make_bundler_task path, module_name, tasks
  make_run_task path, module_name, 'validate', tasks
  make_run_task path, module_name, 'spec', tasks
  make_run_task path, module_name, 'lint', tasks
  make_run_task path, module_name, 'spec_clean', tasks

  desc "Run all tests for the module: #{module_name}"
  task module_name => tasks[module_name]
end

desc 'Run all bundler tasks'
task 'bundler' => tasks[:bundler]

desc 'Run all the spec tasks'
task 'spec' => tasks[:spec]

desc 'Run all the validate tasks'
task 'validate' => tasks[:validate]

desc 'Run all the lint tasks'
task 'lint' => tasks[:lint]

desc 'Run all the tests for all the modules'
task 'test' => (tasks[:validate] || []) + (tasks[:spec] || []) + (tasks[:lint] || [])

desc 'Run the spec_clean for all the modules'
task 'spec_clean' => tasks[:spec_clean]

task :clean => 'spec_clean'
task :default => 'test'
task :syntax => 'validate'

at_exit do
  check_empty_report
  show_report
  exit_with_error_code
end
