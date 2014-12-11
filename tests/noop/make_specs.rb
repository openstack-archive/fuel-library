#!/usr/bin/env ruby
require 'find'
require 'fileutils'

DIR=File.dirname __FILE__
Dir.chdir DIR or raise "Cannot cd to #{DIR}"

MODULAR_DIR='../../deployment/puppet/osnailyfacter/modular/'
SPEC_DIR='generate'
BASE_SPEC='spec/hosts/hiera_spec.rb'

base_spec_content = File.read BASE_SPEC

Find.find(MODULAR_DIR) do |file|
  next unless File.file? file
  next unless file.end_with? '.pp'
  short_name = file.gsub MODULAR_DIR, ''
  spec_path = File.join SPEC_DIR, short_name.gsub('.pp', '_spec.rb')
  spec_content = base_spec_content.gsub 'hiera.pp', short_name
  puts "Write spec: '#{spec_path}'"
  spec_dir = File.dirname spec_path
  FileUtils.mkdir_p spec_dir unless File.directory? spec_dir
  File.open(spec_path, 'w') { |f| f.write spec_content }
end
