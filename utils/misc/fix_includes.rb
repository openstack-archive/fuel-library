#!/usr/bin/env ruby
require 'find'

module FixIncludes
  def self.dirs
    ARGV
  end

  def self.manifests
    manifests = []
    dirs.each do |dir|
      puts "Process dir: #{dir}"
      for_each_manifest_in(dir) do |file|
        manifests << file
      end
    end
    manifests
  end

  def self.for_each_manifest_in(dir)
    Find.find(dir) do |file|
      next unless file.end_with? '.pp'
      next unless File.file? file
      yield file
    end
  end

  def self.process_manifest(file)
    puts "Process file: #{file}"
    content = File.read file
    return unless content
    processed_lines = []
    lines = content.split("\n")
    lines.each do |line|
      if line =~ regexp
        indent = $1.length
        class_name = $2
        new_line = "#{' ' * indent}class { '::#{class_name}' :}"
        puts new_line
        processed_lines << new_line
      else
        processed_lines << line
      end
    end
    processed_lines.join "\n"
  end

  def self.regexp
    %r(^(\s*)(?:include|require)\s+["']*:+([\w:_-]+)['"]*)
  end

  def self.main
    manifests.each do |file|
      content = process_manifest file
      File.open(file, 'w') do |file|
        file.puts content
      end
    end
  end
end

if $0 == __FILE__
  FixIncludes.main
end
