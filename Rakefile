###############################################################################
#
#    Copyright 2015 Mirantis, Inc.
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
#
###############################################################################
#
# Rakefile
#   This file implements the lint and spec tasks for rake so that it will loop
#   through all of the puppet modules in the deployment/puppet/ folder and run
#   the respective lint or test tasks for each module. It will then return 0 if
#   there are issues or return 1 if any of the modules fail.
#
# Authors: Alex Schultz <aschultz@mirantis.com>
#          Maksim Malchuk <mmalchuk@mirantis.com>
#
require 'rake'

# Use puppet-syntax for the syntax tasks
require 'puppet-syntax/tasks/puppet-syntax'
PuppetSyntax.exclude_paths ||= []
PuppetSyntax.exclude_paths << "**/spec/fixtures/**/*"
PuppetSyntax.exclude_paths << "**/pkg/**/*"
PuppetSyntax.exclude_paths << "**/vendor/**/*"


# Main task list
task :default => ["common:help"]
task :help => ["common:help"]

# RSpec task list
desc "Pull down module dependencies, run tests against Git changes and cleanup"
task :spec => ["spec:prep", "spec:gemfile", "spec:clean"]
task :spec_all => ["spec:all"]
task :spec_prep => ["spec:prep"]
task :spec_clean => ["spec:clean"]
task :spec_standalone => ["spec:gemfile"]

# Lint task list
# TODO(aschultz): Use puppet-lint for the lint tasks
desc "Run lint tasks"
task :lint => ["lint:manual"]
task :lint_all => ["lint:all"]
task :lint_manual => ["lint:manual"]

# Syntax task list
task :syntax => ["syntax:manifests", "syntax:hiera", "syntax:files", "syntax:templates"]
task :syntax_files => ["syntax:files"]


# The common tasks is for internal use, so its description is commented
namespace :common do

  # desc "Task to load list of modules to skip"
  task :load_skip_file, :skip_file do |t, args|

    def mod(name, options = {})
      @modules ||= {}
      module_name = name.split('/', 2).last
      @modules[module_name] = options
    end

    module_list = []

    library_dir = Dir.pwd
    ["#{library_dir}/deployment/Puppetfile",
    "#{library_dir}/deployment/puppet/openstack_tasks/Puppetfile"].each do |puppetfile|
      if File.exists?(puppetfile)
        eval(File.read(puppetfile))
        @modules.each { |module_name|
          module_list << module_name[0]
        }
      end
    end

    # TODO(aschultz): Fix all modules so they have tests and we no longer need
    # this file to exclude bad module tests
    if not args[:skip_file].nil? and File.exists?(args[:skip_file])
      File.open(args[:skip_file], 'r').each_line { |line|
        next if line =~ /^\s*#/
        module_list << line.chomp
      }
    end

    $skip_module_list = module_list.uniq
  end

  # desc "Task to generate a list of modules with Git changes"
  task :modulesgit, [:skip_file] do |t, args|
    args.with_defaults(:skip_file => nil)

    $module_directories = []

    $git_module_directories = %x[git diff --name-only HEAD~ 2>/dev/null |\
      grep -o 'deployment/puppet/[^/]*/' | sort -u].split.select {|mod| File.directory? mod}

    if $git_module_directories.empty?
      Rake::Task["common:modules"].invoke(args[:skip_file])
    else
      Rake::Task["common:load_skip_file"].invoke(args[:skip_file])

      $stderr.puts '-'*80
      $stderr.puts "Git changes found! Build modules list..."
      $stderr.puts '-'*80
      $git_module_directories.each do |mod|
        if $skip_module_list.include?(File.basename(mod))
          $stderr.puts "Skipping tests... modules.disable_rspec includes #{mod}"
          next
        end
        $module_directories << mod
      end
    end
  end

  # desc 'Task to generate a list of all modules'
  task :modules, [:skip_file] do |t, args|
    args.with_defaults(:skip_file => nil)

    $module_directories = []

    Rake::Task["common:load_skip_file"].invoke(args[:skip_file])

    $stderr.puts '-'*80
    $stderr.puts "No changes found! Build modules list..."
    $stderr.puts '-'*80
    Dir.glob('deployment/puppet/*') do |mod|
      next unless File.directory?(mod)
      if $skip_module_list.include?(File.basename(mod))
        $stderr.puts "Skipping tests... modules.disable_rspec includes #{mod}"
        next
      end
      $module_directories << mod
    end
  end

  # desc "Display the list of available rake tasks"
  task :help do
    system("rake -T")
  end
end


# our spec tasks to loop through the modules and run the 'rake spec'
namespace :spec do

  desc 'Run prep to install gems and pull down module dependencies'
  task :prep do |t|
    $stderr.puts '-'*80
    $stderr.puts "Install gems and pull down module dependencies..."
    $stderr.puts '-'*80
    library_dir = Dir.pwd
    ENV['GEM_HOME']="#{library_dir}/.bundled_gems"
    system("gem install bundler --no-rdoc --no-ri --verbose")
    system("./deployment/update_modules.sh")
  end

  desc 'Remove module dependencies'
  task :clean do |t|
    system("./deployment/remove_modules.sh")
  end

  desc "Pull down module dependencies, run tests against all modules and cleanup"
  task :all do |t|
    Rake::Task["spec:prep"].invoke
    Rake::Task["common:modules"].invoke('./utils/jenkins/modules.disable_rspec')
    Rake::Task["spec:gemfile"].invoke
    Rake::Task["spec:clean"].invoke
  end

  desc 'Run spec tasks via module bundler with Gemfile'
  task :gemfile do |t|

    if $module_directories.nil?
      Rake::Task["common:modulesgit"].invoke('./utils/jenkins/modules.disable_rspec')
    end

    library_dir = Dir.pwd
    ENV['GEM_HOME']="#{library_dir}/.bundled_gems"

    status = true
    $module_directories.each do |mod|
      next unless File.exists?("#{mod}/Gemfile")
      $stderr.puts '-'*80
      $stderr.puts "Running tests for #{mod}"
      $stderr.puts '-'*80
      Dir.chdir(mod)
      begin
        result = system("bundle exec rake spec")
        if !result
          status = false
          $stderr.puts "!"*80
          $stderr.puts "Unit tests failed for #{mod}"
          $stderr.puts "!"*80
        end
        rescue Exception => e
          $stderr.puts "ERROR: Unable to run tests for #{mod}, #{e.message}"
          status = false
        end
        Dir.chdir(library_dir)
    end
    fail unless status
  end
end


# our lint tasks to loop through the modules and run the puppet-lint
namespace :lint do

  desc 'Find all the puppet modules and run puppet-lint on them'
  task :all do |t|
    Rake::Task["common:modules"].invoke('./utils/jenkins/modules.disable_rake-lint')
    Rake::Task["lint:manual"].invoke
  end

  desc 'Find the puppet modules with Git changes and run puppet-lint on them'
  task :manual do |t|

    if $module_directories.nil?
      Rake::Task["common:modulesgit"].invoke('./utils/jenkins/modules.disable_rake-lint')
    end

    # lint checks to skip if no Gemfile or Rakefile
    skip_checks = [ "--no-80chars-check",
        "--no-autoloader_layout-check",
        "--no-only_variable_string-check",
        "--no-2sp_soft_tabs-check",
        "--no-trailing_whitespace-check",
        "--no-hard_tabs-check",
        "--no-class_inherits_from_params_class-check",
        "--with-filename"]

    $stderr.puts '-'*80
    $stderr.puts "Install gems..."
    $stderr.puts '-'*80
    library_dir = Dir.pwd
    ENV['GEM_HOME']="#{library_dir}/.bundled_gems"
    system("gem install bundler --no-rdoc --no-ri --verbose")

    status = true
    $module_directories.each do |mod|
      # TODO(aschultz): uncomment this when :rakefile works
      #next if File.exists?("#{mod}/Rakefile")
      $stderr.puts '-'*80
      $stderr.puts "Running lint for #{mod}"
      $stderr.puts '-'*80
      Dir.chdir(mod)
      begin
        result = true
        Dir.glob("**/**.pp") do |puppet_file|
          result = false unless system("puppet-lint #{skip_checks.join(" ")} #{puppet_file}")
        end
        if !result
          status = false
          $stderr.puts "!"*80
          $stderr.puts "puppet-lint failed for #{mod}"
          $stderr.puts "!"*80
        end
      rescue Exception => e
          $stderr.puts "ERROR: Unable to run lint for #{mod}, #{e.message}"
          status = false
      end
      Dir.chdir(library_dir)
    end
    fail unless status
  end

  # TODO(aschultz): fix all the modules with Rakefiles to make sure they work
  # then include this task
  desc 'Find the puppet modules with Git changes and run lint tasks using existing Gemfile/Rakefile'
  task :rakefile do |t|

    Rake::Task["common:modulesgit"].invoke('./utils/jenkins/modules.disable_rake-lint')

    $stderr.puts '-'*80
    $stderr.puts "Install gems..."
    $stderr.puts '-'*80
    library_dir = Dir.pwd
    ENV['GEM_HOME']="#{library_dir}/.bundled_gems"
    system("gem install bundler --no-rdoc --no-ri --verbose")

    status = true
    $module_directories.each do |mod|
      next unless File.exists?("#{mod}/Rakefile")
      $stderr.puts '-'*80
      $stderr.puts "Running lint for #{mod}"
      $stderr.puts '-'*80
      Dir.chdir(mod)
      begin
        result = system("bundle exec rake lint >/dev/null")
        $stderr.puts result
        if !result
          status = false
          $stderr.puts "!"*80
          $stderr.puts "rake lint failed for #{mod}"
          $stderr.puts "!"*80
        end
      rescue Exception => e
        $stderr.puts "ERROR: Unable to run lint for #{mod}, #{e.message}"
        status = false
      end
      Dir.chdir(library_dir)
    end
    fail unless status
  end
end

# Our syntax checking jobs
# The tasks here are an extension on top of the existing puppet helper ones.
namespace :syntax do
  desc 'Syntax check for files/ folder'
  task :files do |t|

    $stderr.puts '---> syntax:files'
    status = true
    Dir.glob('./files/**/*') do |ocf_file|
      next if File.directory?(ocf_file)

      mime_type =`file --mime --brief #{ocf_file}`
      begin
        case mime_type.to_s
        when /shellscript/
          result = system("bash -n #{ocf_file}")
        when /ruby/
          result = system("ruby -c #{ocf_file}")
        when /python/
          result = system("python -m py_compile #{ocf_file}")
        when /perl/
          result = system("perl -c #{ocf_file}")
        else
          result = true
          $stderr.puts "Unknown file format, skipping syntax check for #{ocf_file}"
        end
      rescue Exception => e
        result = false
        $stderr.puts "Checking #{ocf_file} failed with #{e.message}"
      end
      if !result
        status = false
        $stderr.puts "!"*80
        $stderr.puts "Syntax check failed for #{ocf_file}"
        $stderr.puts "!"*80
      end
    end
    fail unless status
  end
end
