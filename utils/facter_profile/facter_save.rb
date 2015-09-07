#!/usr/bin/env ruby

# a stand-alone script to save fact to a yaml file for caching

PUPPET_DIR = '/etc/puppet/modules'
FACTS_DIR = '/var/lib/puppet/lib/facter'
CACHE_DIR = '/etc/facter/facts.d'

def debug(message)
  # puts message
end

def error(message)
  puts message
end

def check_dirs
  unless File.directory? PUPPET_DIR
    error "No dir: #{PUPPET_DIR}"
    exit 1
  end
  FileUtils.mkdir_p FACTS_DIR
  unless File.directory? FACTS_DIR
    error "No dir: #{PUPPET_DIR}"
    exit 1
  end
  FileUtils.mkdir_p CACHE_DIR
  unless File.directory? CACHE_DIR
    error "No dir: #{CACHE_DIR}"
    exit 1
  end
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

def save_facts_to_yaml
  system "facter -p -y > '#{CACHE_DIR}/cache.yaml'"
end

###############################################################################

check_dirs
purge_facts
copy_puppet_facts
save_facts_to_yaml
purge_facts
