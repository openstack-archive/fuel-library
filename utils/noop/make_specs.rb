#!/usr/bin/env ruby
require 'find'

DIR=File.dirname __FILE__
Dir.chdir DIR or raise "Cannot cd to #{DIR}"

MODULAR_DIR='../../deployment/puppet/osnailyfacter/modular/'
SPEC_DIR='generate'
BASE_SPEC='spec/hosts/hiera_spec.rb'

base_spec_content = File.read BASE_SPEC
Dir.mkdir SPEC_DIR unless File.directory? SPEC_DIR

Find.find(MODULAR_DIR) do |file|
  next unless File.file? file
  next unless file.end_with? '.pp'
  short_name = file.gsub MODULAR_DIR, ''
  spec_path = File.join SPEC_DIR, short_name.gsub('.pp', '_spec.rb')
  spec_content = base_spec_content.gsub 'hiera.pp', short_name
  puts "Write spec: '#{spec_path}'"
  File.open(spec_path, 'w') { |f| f.write spec_content }
end
