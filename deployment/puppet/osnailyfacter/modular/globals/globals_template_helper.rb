#!/usr/bin/env ruby

dir = File.dirname(__FILE__)
Dir.chdir dir

globals = 'globals.pp'
template_dir = '../../templates'
raise 'No globlas.pp!' unless File.exist? globals
raise 'No template dir!' unless File.directory? template_dir

variables = []

File.open(globals, 'r').each do |line|
  if line =~ /^\s*\$(\S+)\s+=/
    next if $1.include? '['
    variables << $1 unless variables.include? $1
  end
end

variables.sort!

template = File.join template_dir, 'globals_yaml.erb'
File.open(template, 'w') do |file|
  file.puts '<% require "yaml" -%>'
  file.puts '<% globals = {} -%>'
  variables.each do |var|
    file.puts "<% globals.store \"#{var}\", @#{var} -%>"
  end
  file.puts '<%= YAML.dump globals %>'
end

puts File.read template
