#!/usr/bin/env ruby

###############################################################################
#
#    Copyright 2016 Mirantis, Inc.
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

require 'pathname'
require 'optparse'
require 'timeout'

module PuppetModules
  # all actions that can be entered as the first argument of the command
  ALLOWED_ACTIONS = %w(console list restore compress status update reset install remove reinstall)
  # this action will be used if no action is provided
  DEFAULT_ACTION = 'install'
  # the maximum allowed time for the command to run
  TIMEOUT = 600

  # parse the command line options
  # @return [Hash]
  def self.options
    return @options if @options
    @options = {}
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: puppet_modules [options] [#{ALLOWED_ACTIONS.join '|'}]"
      opts.separator 'Main options:'
      opts.on('-f', '--file FILE', 'Use this Puppetfile') do |value|
        @options[:puppetfile] = value
      end
      opts.on('-d', '--puppet_dir DIR', 'Install puppet modules into this directory') do |value|
        @options[:puppet_dir] = value
      end
      opts.on('-v', '--[no-]verbose', 'Run verbosely') do |value|
        @options[:verbose] = value
      end
      opts.on('-t', '--[no-]test', 'Perform self-tests') do |value|
        @options[:test] = value
      end
      opts.on('-i', '--install', 'Install all external Puppet modules') do
        @options[:action] = :install
      end
      opts.on('-r', '--reinstall', 'Remove modules and install them again') do
        @options[:action] = :reinstall
      end
      opts.on('-R', '--reset', 'Reset Git of all external Puppet modules') do
        @options[:action] = :reset
      end
      opts.on('-x', '--remove', 'Remove external Puppet modules') do
        @options[:action] = :remove
      end
      opts.on('-u', '--update', 'Update external Puppet modules') do
        @options[:action] = :update
      end
      opts.on('-s', '--status', 'Show git status of the external Puppet modules') do
        @options[:action] = :status
      end
      opts.on('-c', '--compress', 'Compress external Puppet modules to the archive file') do
        @options[:action] = :compress
      end
      opts.on('-e', '--restore', 'Restore external Puppet modules from the archive file') do
        @options[:action] = :restore
      end
      opts.on('-l', '--list', 'List external puppet modules') do
        @options[:action] = :list
      end
      opts.on('-C', '--console', 'Run pry console') do
        @options[:action] = :console
      end

      opts.separator 'Gem options:'
      opts.on('-b', '--[no-]bundler', 'Setup and use "bundler"') do |value|
        @options[:bundler] = value
      end
      opts.on('-g', '--gem_home DIR', 'Use this folder as a GEM_HOME') do |value|
        ENV['GEM_HOME'] = value
      end
      opts.on('-p', '--puppet_gem VERSION', 'Use this version of Puppet gem') do |value|
        ENV['PUPPET_GEM_VERSION'] = value
      end

    end
    parser.separator "Default action: #{DEFAULT_ACTION}" if DEFAULT_ACTION
    parser.parse!
    @options
  end

  # Output a line of text
  # @param message [String]
  def self.output(message)
    puts message
  end

  # Output an error message and exit
  # @param message [String]
  def self.error(message)
    output 'ERROR: ' + message
    exit 1
  end

  # check if any version of puppet librarian is installed
  # @return [true,false]
  def self.librarian_puppet_installed?
    cmd = 'librarian-puppet -h 1>/dev/null 2>/dev/null'
    system cmd
    $?.exitstatus == 0
  end

  # check if this version of librarian is puppet-librarian-simple
  # @return [true,false]
  def self.librarian_puppet_simple?
    cmd = 'librarian-puppet help generate_puppetfile 1>/dev/null 2>/dev/null'
    system cmd
    $?.exitstatus == 0
  end

  # check if timeout command is installed
  # @return [true,false]
  def self.timeout_installed?
    return @timeout_installed unless @timeout_installed.nil?
    cmd = 'which timeout 1>/dev/null 2>/dev/null'
    system cmd
    @timeout_installed = ($?.exitstatus == 0)
  end

  # check if the puppetfile is present
  # @return [true,false]
  def self.file_present_puppetfile?
    file_path_puppetfile.readable?
  end

  # check if the puppetfile contains any modules records
  # @return [true,false]
  def self.puppetfile_modules_present?
    module_names.any?
  end

  # check if the archive of saved puppet modules is present
  # @return [true,false]
  def self.file_present_archive?
    file_path_archive.file?
  end

  # check if the puppet modules directory exists
  # @return [true,false]
  def self.dir_present_puppet?
    dir_path_puppet.directory?
  end

  # check if the provided directory has a git repository inside
  # @return [true, false]
  def self.git_present?(directory)
    directory = Pathname.new directory unless directory.is_a? Pathname
    git = directory + dir_name_git
    git.directory?
  end

  # the root path of this script
  # should be the 'deployment' folder
  # @return [Pathname]
  def self.dir_path_root
    Pathname.new(__FILE__).dirname.realpath
  end

  # puppetfile file name
  # @return [Pathname]
  def self.file_name_puppetfile
    Pathname.new 'Puppetfile'
  end

  # full path to a puppetfile
  # @return [Pathname]
  def self.file_path_puppetfile
    return Pathname.new options[:puppetfile] if options[:puppetfile]
    dir_path_root + file_name_puppetfile
  end

  # the name of the directory with puppet modules
  # @return [Pathname]
  def self.dir_name_puppet
    Pathname.new 'puppet'
  end

  # full path to the directory with puppet modules
  # @return [Pathname]
  def self.dir_path_puppet
    return Pathname.new options[:puppet_dir] if options[:puppet_dir]
    dir_path_root + dir_name_puppet
  end

  # the name of the file used as puppet modules archive
  # @return [Pathname]
  def self.file_name_archive
    Pathname.new 'puppet_modules.tgz'
  end

  # full path to the puppet modules archive file
  # @return [Pathname]
  def self.file_path_archive
    dir_path_root + file_name_archive
  end

  # the name of gemfile lock file
  # @return [Pathname]
  def self.file_name_gemfile_lock
    Pathname.new 'Gemfile.lock'
  end

  # full path to the gemfile lock file
  # @return [Pathname]
  def self.file_path_gemfile_lock
    dir_path_root + file_name_gemfile_lock
  end

  # the name of the git repository folder
  # @return [Pathname]
  def self.dir_name_git
    Pathname.new '.git'
  end

  # Run a command inside the provided directory
  # and then return back. Returns true on success.
  # @param directory [String, Pathname]
  # @param command [String]
  # @return [true,false]
  def self.run_inside_directory(directory, command)
    directory = directory.to_s
    error "Cannot run command inside: '#{directory}'! Directory does not exist!" unless File.directory? directory
    Dir.chdir(directory) do
      command = "timeout #{TIMEOUT} " + command if timeout_installed?
      output "Run: #{command} (dir: #{directory})"
      system command
    end
  end

  # extract the list of external puppet module names
  # from the puppetfile
  # @return [Array<String>]
  def self.module_names
    modules = []
    return modules unless file_present_puppetfile?
    begin
    file_path_puppetfile.read.split("\n").each do |line|
      if line =~ %r(^\s*mod\s+['"]+(\S+)['"]+)
        modules << $1 if $1
      end
    end
    rescue
      []
    end
    modules
  end

  # get the array of full paths to external Puppet modules
  # @return [Array<Pathname>]
  def self.module_full_paths
    module_names.map do |module_name|
      dir_path_puppet + Pathname.new(module_name)
    end
  end

  # remove all external puppet modules
  def self.modules_remove
    module_full_paths.each do |module_path|
      if module_path.directory?
        output "Remove: '#{module_path}'"
        module_path.rmtree
      end
    end
  end

  # use tar to compress all external puppet modules
  def self.modules_compress
    modules = module_names.join ' '
    command = "tar -czpvf #{file_path_archive} #{modules}"
    success = run_inside_directory dir_path_puppet, command
    if success
      output "Archive of modules from: '#{dir_path_puppet}' written to: '#{file_path_archive}'"
    else
      error "Error writing modules archive to: '#{file_path_archive}'"
    end
  end

  # first remove all modules, then restore the saved puppet modules
  def self.modules_restore
    error "The archive of external Puppet modules '#{file_path_archive}' doesn't exist!" unless file_present_archive?
    modules_remove
    command = "tar -xpvf #{file_path_archive}"
    success = run_inside_directory dir_path_puppet, command
    if success
      output "Archive restored from: '#{file_path_archive}' to: '#{dir_path_puppet}'"
    else
      error "Error restoring modules archive from: '#{file_path_archive}'"
    end
  end

  # prepare the command line and run the librarian command
  # @param command [String]
  # @return [true,false]
  def self.librarian_puppet_command(command)
    command = "librarian-puppet #{command}"
    command += " --path=#{dir_path_puppet}"
    command += " --puppetfile=#{file_path_puppetfile}"
    command += ' --verbose' if options[:verbose]
    command = 'bundle exec ' + command if options[:bundler]
    run_inside_directory dir_path_root, command
  end

  # use librarian to install all external Puppet modules
  def self.modules_install
    success = librarian_puppet_command 'install'
    error 'Modules installation failed!' unless success
  end

  # use librarian to install and then update Puppet modules
  def self.modules_update
    modules_install
    success = librarian_puppet_command 'update'
    error 'Modules update failed!' unless success
  end

  # use librarian to query git status of external Puppet modules
  def self.modules_status
    librarian_puppet_command 'git_status'
  end

  # run hard git reset inside this directory
  # if there is a git repository present
  # @param directory [String, Pathname]
  # @return [true,false]
  def self.git_reset_hard(directory)
    unless git_present? directory
      output "There is no Git repository in: '#{directory}'!"
      return false
    end
    success = run_inside_directory directory, 'git reset --hard'
    return success unless success
    success = run_inside_directory directory, 'git clean -f -d -x'
    success
  end

  # try to reset git repository inside
  # every external Puppet modules
  def self.modules_reset
    module_full_paths.each do |module_path|
      success = git_reset_hard module_path
      output "Reset git FAILED in: '#{module_path}'" unless success
    end
  end

  # first, remove all modules then install them again
  def self.modules_reinstall
    modules_remove
    modules_install
  end

  # run a bunch of self check operations
  def self.perform_tests
    output 'Running self tests...'
    error "You have no 'librarian-puppet-simple' installed! Try to use '-b' option." unless librarian_puppet_installed?
    error "You have installed 'librarian-puppet' instead of 'librarian-puppet-simple'!" unless librarian_puppet_simple?
    error "There is no Puppetfile: '#{file_path_puppetfile}'!" unless file_present_puppetfile?
    error "Could not find any modules in Puppetfile: '#{file_path_puppetfile}'! Something is wrong with it!" unless puppetfile_modules_present?
    error "There is no Puppet modules directory: '#{dir_path_puppet}'!" unless dir_present_puppet?
  end

  # try to decode the actions from the script's command line
  # or take the default action
  def self.actions
    return if options[:action]
    options[:action] = DEFAULT_ACTION.to_sym
    action = ARGV.first
    if action
      error "There is no action: '#{action}'!" unless ALLOWED_ACTIONS.include? action
      options[:action] = action.to_sym
    end
  end

  # run the pry console inside this module
  def self.console
    require 'pry'
    binding.pry
    exit 0
  end

  # remove the gemfile lock file if it's present
  def self.remove_gemfile_lock
    if file_path_gemfile_lock.file?
      output "Remove file: '#{file_path_gemfile_lock}'"
      file_path_gemfile_lock.unlink
    end
  end

  # prepare and update the bundler environment
  def self.prepare_bundler
    output 'Preparing bundler...'
    remove_gemfile_lock
    success = run_inside_directory dir_path_root, 'bundle install'
    error 'Bundler install command failed!' unless success
    success = run_inside_directory dir_path_root, 'bundle update'
    error 'Bundler update command failed!' unless success
  end

  # output the list of all external Puppet modules
  def self.modules_list
    output module_names.sort.join "\n"
  end

  # run all preparation functions if they are enabled by options
  def self.preparations
    prepare_bundler if options[:bundler]
    perform_tests if options[:test]
  end

  # run a block of code with timeout
  def self.with_timeout
    begin
      Timeout.timeout(TIMEOUT) do
        yield
      end
    rescue Timeout::Error
       error "Timeout of '#{TIMEOUT}' seconds is expired! The action was: '#{options[:action]}'"
    end
  end

  # the main procedure
  def self.main
    options
    actions
    preparations

    with_timeout do
      case options[:action]
        when :console; console
        when :list; modules_list
        when :restore; modules_restore
        when :compress; modules_compress
        when :status; modules_status
        when :update; modules_update
        when :reset; modules_reset
        when :install; modules_install
        when :remove; modules_remove
        when :reinstall; modules_reinstall
        else error 'There is no action specified!'
      end
    end

  end
end

PuppetModules.main
