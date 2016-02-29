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

module PuppetModules
  ALLOWED_ACTIONS = %w(console list restore compress status update reset install remove bundler)
  DEFAULT_ACTION = 'install'

  # BASE

  def self.output(message)
    puts message
  end

  def self.error(message)
    puts message
    exit 1
  end

  # CHECKS

  def self.librarian_puppet_installed?
    cmd = 'librarian-puppet -h'
    `#{cmd}`
    $?.exitstatus == 0
  end

  def self.librarian_puppet_simple?
    cmd = 'librarian-puppet help generate_puppetfile'
    `#{cmd}`
    $?.exitstatus == 0
  end

  def self.file_present_puppetfile?
    file_path_puppetfile.readable?
  end

  def self.puppetfile_modules_present?
    module_names.any?
  end

  # PATHS

  def self.dir_path_root
    Pathname.new(__FILE__).dirname.realpath
  end

  def self.file_name_puppetfile
    Pathname.new 'Puppetfile'
  end

  def self.file_path_puppetfile
    dir_path_root + file_name_puppetfile
  end

  def self.dir_name_puppet
    Pathname.new 'puppet'
  end

  def self.dir_path_puppet
    dir_path_root + dir_name_puppet
  end

  def self.file_name_archive
    Pathname.new 'puppet_modules.tgz'
  end

  def self.file_path_archive
    dir_path_root + file_name_archive
  end

  def self.file_name_gemfile_lock
    Pathname.new 'Gemfile.lock'
  end

  def self.file_path_gemfile_lock
    dir_path_root + file_name_gemfile_lock
  end

  # ACTIONS

  def self.inside_root(&block)
    Dir.chdir(dir_path_root.to_s, &block)
  end

  def self.run_inside_root(cmd)
    output "Run: #{cmd}"
    inside_root do
      system cmd
    end
  end

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

  def self.module_full_paths
    module_names.map do |module_name|
      dir_path_puppet + Pathname.new(module_name)
    end
  end

  def self.module_short_paths
    module_names.map do |module_name|
      dir_name_puppet + Pathname.new(module_name)
    end
  end

  def self.modules_remove
    module_full_paths.each do |module_path|
      if module_path.directory?
        output "Remove: '#{module_path}'"
        module_path.rmtree
      end
    end
  end

  def self.modules_compress
    modules = module_short_paths.join ' '
    cmd = "tar -czpvf #{file_path_archive} #{modules}"
    run_inside_root cmd
    output "Archive written to: #{file_path_archive}"
  end

  def self.modules_restore
    modules_remove
    cmd = "tar -xpvf #{file_path_archive}"
    run_inside_root cmd
    output "Archive restored from: #{file_path_archive}"
  end

  def self.librarian_puppet_command(command)
    cmd = "librarian-puppet #{command}"
    cmd += " --path=#{dir_path_puppet}"
    cmd += " --puppetfile=#{file_path_puppetfile}"
    cmd += ' --verbose' if options[:verbose]
    cmd = 'bundle exec ' + cmd if options[:bundler]
    run_inside_root cmd
  end

  def self.modules_install
    prepare_bundler if options[:bundler]
    librarian_puppet_command 'install'
  end

  def self.modules_update
    prepare_bundler if options[:bundler]
    librarian_puppet_command 'install'
    librarian_puppet_command 'update'
  end

  def self.modules_status
    prepare_bundler if options[:bundler]
    librarian_puppet_command 'git_status'
  end

  def self.modules_reset
    prepare_bundler if options[:bundler]
    modules_remove
    librarian_puppet_command 'install'
  end

  def self.perform_tests
    output 'Running self tests...'
    error "You have no 'librarian-puppet-simple' installed!" unless librarian_puppet_installed?
    error "You have installed 'librarian-puppet' instead of 'librarian-puppet-simple'!" unless librarian_puppet_simple?
    error "There is no Puppetfile!" unless file_present_puppetfile?
    error "Could not find any modules in your Puppetfile! Something is wrong with it!" unless puppetfile_modules_present?
  end

  def self.options
    return @options if @options
    @options = {}
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: puppet_modules [options] [#{ALLOWED_ACTIONS.join '|'}]"
      opts.separator 'Main options:'
      opts.on('-f', '--file FILE', 'Use this Puppetfile') do |value|
        @options[:puppetfile] = value
      end
      opts.on('-v', '--[no-]verbose', 'Run verbosely') do |value|
        @options[:verbose] = value
      end
      opts.on('-t', '--[no-]test', 'Perform self-tests') do |value|
        @options[:test] = value
      end
      opts.on('-r', '--reset', 'Reset external Puppet modules') do
        @options[:action] = :reset
      end
      opts.on('-R', '--remove', 'Remove external Puppet modules') do
        @options[:action] = :reset
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

  def self.actions
    return if options[:action]
    options[:action] = DEFAULT_ACTION.to_sym
    action = ARGV.first
    if action
      error "There is no action: '#{action}'!" unless ALLOWED_ACTIONS.include? action
      options[:action] = action.to_sym
    end
  end

  def self.console
    require 'pry'
    binding.pry
    exit 0
  end

  def self.remove_gemfile_lock
    if file_path_gemfile_lock.file?
      output "Remove file: #{file_path_gemfile_lock}"
      file_path_gemfile_lock.unlink
    end
  end

  def self.prepare_bundler
    output 'Preparing bundler...'
    remove_gemfile_lock
    run_inside_root 'bundler install'
    run_inside_root 'bundler update'
  end

  def self.modules_list
    output module_names.join "\n"
  end

  def self.main
    options
    actions
    perform_tests if options[:test]

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
      when :bundler; prepare_bundler
      else error 'There is no action specified!'
    end

  end
end

PuppetModules.main
