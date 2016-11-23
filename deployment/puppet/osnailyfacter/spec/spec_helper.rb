require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'webmock/rspec'

PROJECT_ROOT = File.expand_path '..', File.dirname(__FILE__)

def add_plugin_lib_dir(*plugin_dirs)
  plugin_dirs.each do |plugin_dir|
    lib_dir = File.join plugin_dir, 'lib'
    next unless File.directory? lib_dir
    # puts "Add lib dir to the load path: '#{lib_dir}'"
    $LOAD_PATH << lib_dir
  end
end

def add_fixtures_lib_dirs
  fixture_modules_dir = File.join PROJECT_ROOT, 'spec', 'fixtures', 'modules'
  return unless File.directory? fixture_modules_dir
  Dir.entries(fixture_modules_dir).each do |plugin|
    next if %w(. ..).include? plugin
    plugin_dir = File.join fixture_modules_dir, plugin
    add_plugin_lib_dir plugin_dir
  end
end

add_plugin_lib_dir PROJECT_ROOT
add_fixtures_lib_dirs

RSpec.configure do |c|
  c.mock_with(:mocha)
  c.alias_it_should_behave_like_to :it_configures, 'configures'
end

def puppet_debug_override
  if ENV['SPEC_PUPPET_DEBUG']
    Puppet::Util::Log.level = :debug
    Puppet::Util::Log.newdestination(:console)
  end
end
