#!/usr/bin/env ruby

# this script runs facter and gathers facts timing
# for prifiling purposes

require 'find'
require 'fileutils'
require 'time'

PUPPET_DIR = '/etc/puppet/modules'
FACTS_DIR = '/var/lib/puppet/lib/facter'

def debug(message)
  # puts message
end

def print(message)
  puts message
end

def check_dirs
  unless File.directory? PUPPET_DIR
    debug "No dir: #{PUPPET_DIR}"
    exit 1
  end
  FileUtils.mkdir_p FACTS_DIR
end

def purge_facts
  Find.find FACTS_DIR do |file|
    next unless File.file? file
    next unless file.end_with? '.rb'
    debug "Remove fact: '#{file}'"
    File.unlink file
  end
end

def copy_puppet_facts
  Find.find PUPPET_DIR do |file|
    next unless File.file? file
    next unless file.end_with? '.rb'
    next unless file.include? '/lib/facter/'
    debug "Copy: '#{file}' to '#{FACTS_DIR}'"
    FileUtils.cp file, FACTS_DIR
  end
end

def run_facter
  start = Time.now
  out = `facter -p -t 2>&1`
  run_time = Time.now - start
  [out, run_time]
end

def clear_string(str)
  str.gsub /\e\[.*?m/, ''
end

def clear_time(time)
  time = time.gsub /[^0-9,\.]*/, ''
  time = Float time rescue nil
  time
end

def facter_timings
  timings = {}
  out, run_time = run_facter
  out.split("\n").each do |line|
    next unless line =~ /^(\S+):\s+([\d\.]+)ms/
    debug "Found line: #{line}"
    fact = clear_string $1
    time = clear_time clear_string $2
    timings.store fact, time
  end
  print_report timings, run_time
end

def print_report(timing, run_time)
  max_length = timing.keys.max_by { |k| k.length }.length
  timing.sort_by { |fact,time| time }.each do |fact, time|
    print "#{fact.ljust max_length + 1} #{time}ms"
  end
  print "-" * 40
  total = timing.inject(0.0) do |total, fact|
    total + fact.last
  end
  print "Total time: #{(total/1000).round 2} sec"
  print "Run time: #{run_time.round 2} sec"
end

################################################################################

check_dirs
purge_facts
copy_puppet_facts
facter_timings
purge_facts
