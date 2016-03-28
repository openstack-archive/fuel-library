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

require 'optparse'

module PuppetfileValidator
  class PuppetfileTester
    def initalize
      @valid = true
    end

    # flag used to indicate if the puppetfile is valid or not after loading
    def valid
      @valid
    end

    # function used for loading Puppetfile and validating repos and git refs
    # @param [String] name Module name from Puppetfile
    # @param [Hash] args Module parameters
    def mod(name, args = nil)
      puts "INFO: validating module '#{name}'"
      if args.is_a? Hash and args.has_key?(:git) and args.has_key?(:ref)
        if validate_repo(args[:git])
          if args[:ref] == 'master' or args[:ref] =~ /stable\/.*/ or validate_ref(args[:git], args[:ref])
            puts "INFO: module '#{name}' is valid"
          else
            @valid = false
            puts "ERROR: module '#{name}' is not referencing a tag (#{args[:ref]})"
          end
        else
          @valid = false
          puts "ERROR: module '#{name}' doesn't reference a valid repo"
        end
      else
        @valid = false
        puts "ERROR: module '#{name}' doesn't have a git repo or ref"
      end
    end

    # function used to validate that a repo is on fuel-infra
    # @param [String] repo Git repository location
    # @returns [Boolean]
    def validate_repo(repo)
      repo_valid = true
      if /review\.fuel-infra\.org/.match(repo).nil? and /github\.com\/fuel-infra/.match(repo).nil?
        repo_valid = false
      end
      repo_valid
    end

    # function used to validate that a ref is a valid tag for a git repo
    # @param [String] repo Git repository location
    # @param [String] ref Git ref
    # @returns [Boolean]
    def validate_ref(repo, ref)
      ref_valid = true
      cmd = "git ls-remote --tags --exit-code #{repo} #{ref} >/dev/null"
      system(cmd)
      if $?.exitstatus != 0
        ref_valid = false
      end
      ref_valid
    end
  end

  def self.options
    return @options if @options
    @options = {
      :puppetfile => self.puppetfile
    }
    optparse = OptionParser.new do |opts|
      opts.separator 'Options:'
      opts.on('-f', '--puppetfile FILE', 'Path to Puppetfile to validate') do |f|
        @options[:puppetfile] = f
      end
      opts.separator [
        '',
        'Validates Puppetfile based on fuel-library rules for upstream modules.',
        'https://wiki.openstack.org/wiki/Fuel/Library_and_Upstream_Modules',
        '',
        'Return Codes:',
        '  0 - Valid Puppetfile',
        '  1 - Exception occured during processing of Puppetfile',
        '  2 - Not valid Puppetfile per fuel-library guidelines',
      ].join("\n")
    end
    optparse.parse!
    @options
  end

  # The default Puppetfile location for fuel-library
  def self.puppetfile
    File.expand_path File.join File.dirname(__FILE__), '..', '..', 'deployment', 'Puppetfile'
  end

  # Puppetfile validator
  # Returns exit codes indicating the validity of the Puppetfile
  # 0 - OK
  # 1 - Exception thrown during processing
  # 2 - Not valid per fuel-library requirements
  def self.main
    puppetfile_tester = PuppetfileTester.new()
    begin
      puppetfile_tester.instance_eval(File.read(options[:puppetfile]))
    rescue SystemExit => se
    rescue Exception => e
      puts "ERROR: Exception during Puppetfile validation, #{e.message}"
      exit 1
    end
    if puppetfile_tester.valid == false
      exit 2
    end
    exit 0
  end
end

PuppetfileValidator.main if __FILE__ == $0
