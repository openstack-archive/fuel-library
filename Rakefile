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
# Author Alex Schultz <aschultz@mirantis.com>
#

task :spec do |t|
  library_dir = Dir.pwd
  status = true

  # go grab bundler
  ENV['GEM_HOME']="#{library_dir}/.bundled_gems"
  system("gem install bundler --no-rdoc --no-ri --verbose")

  skip_module_list = []
  # TODO(aschultz): Fix all modules so they have tests and we no longer need
  # this file to exclude bad module tests
  if File.exists?('./utils/jenkins/modules.disable_rspec')
    File.open('./utils/jenkins/modules.disable_rspec', 'r').each_line { |line|
      skip_module_list << line.chomp
    }
  end

  Dir.glob('./deployment/puppet/*') do |mod|
    next unless File.directory?(mod)
    if skip_module_list.include?(File.basename(mod))
      puts "Skipping tests... modules.disable_rspec includes #{mod}"
      next
    end

    module_path = mod
    Dir.chdir(module_path)

    puts "-"*80
    puts "Running tests for #{module_path}"
    puts "-"*80

    begin
      result = true
      if File.exists?('Gemfile')
        system("#{library_dir}/.bundled_gems/bin/bundle install --without system_tests")
        result = system("#{library_dir}/.bundled_gems/bin/bundle exec rake spec")
      elsif File.exists?('Rakefile')
        result = system("rake spec")
      else
        puts "!"*80
        puts "No unit tests for #{module_path}"
        puts "!"*80
      end
      if !result
        status = false
        puts "!"*80
        puts "Unit tests failed for #{module_path}"
        puts "!"*80
      end
    rescue Exception => e
      puts "ERROR: Unable to run tests for #{module_path}, #{e.message}"
      status = false
    end
    Dir.chdir(library_dir)
  end
  if !status
      exit 1
  end
  exit 0

end

task :lint do |t|
  # lint checks to skip if no Gemfile or Rakefile
  skip_checks = [ "--no-80chars-check",
    "--no-autoloader_layout-check",
    "--no-nested_classes_or_defines-check",
    "--no-only_variable_string-check",
    "--no-2sp_soft_tabs-check",
    "--no-trailing_whitespace-check",
    "--no-hard_tabs-check",
    "--no-class_inherits_from_params_class-check",
    "--with-filename"]

  library_dir = Dir.pwd
  status = true

  # go grab bundler
  ENV['GEM_HOME']="#{library_dir}/.bundled_gems"
  system("gem install bundler --no-rdoc --no-ri --verbose")

  Dir.glob('./deployment/puppet/*') do |mod|
    next unless File.directory?(mod)

    module_path = mod
    Dir.chdir(module_path)

    puts "-"*80
    puts "Checking lint for #{module_path}"
    puts "-"*80

    begin
      result = true
      if File.exists?('Gemfile')
        system("#{library_dir}/.bundled_gems/bin/bundle install --without system_tests")
        result = system("#{library_dir}/.bundled_gems/bin/bundle exec rake lint")
      # TODO(aschultz): Ensure modules that have Rakefiles have passing lint task.
      #elsif File.exists?('Rakefile')
      #  result = system("rake lint")
      else
        Dir.glob("**/**.pp") do |puppet_file|
          result = false unless system("puppet-lint #{skip_checks.join(" ")} #{puppet_file}")
        end
      end
      if !result
        status = false
        puts "!"*80
        puts "Lint failed for #{module_path}"
        puts "!"*80
      end
    rescue Exception => e
      puts "ERROR: Unable to lint #{module_path}, #{e.message}"
      status = false
    end
    Dir.chdir(library_dir)
  end
  if !status
      exit 1
  end
  exit 0
end
