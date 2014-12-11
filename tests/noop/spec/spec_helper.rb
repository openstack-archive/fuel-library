require 'rubygems'
require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'yaml'

puppet_logs_dir = ENV['PUPPET_LOGS_DIR'] || 'none'

module Noop
  def self.module_path
    return @module_path if @module_path
    @module_path = File.expand_path(File.join(__FILE__, '..', '..', '..', '..', 'deployment', 'puppet'))
  end

  def self.hiera_data_path
    return @hiera_data_path if @hiera_data_path
    @hiera_data_path = File.expand_path(File.join(__FILE__, '..', '..', 'astute.yaml'))
  end

  def self.fixtures_path
    return @fixtures_path if @fixtures_path
    @fixtures_path = File.expand_path(File.join(__FILE__, '..', '..', 'fixtures'))
  end

  def self.astute_yaml_name
    ENV['astute_filename'] || 'ha_neut_vlan.primary-controller.yaml'
  end

  def self.astute_yaml_path
    File.expand_path File.join(self.hiera_data_path, self.astute_yaml_name)
  end

  def self.globals_yaml_path
    File.expand_path File.join(self.hiera_data_path, self.globlas_prefix + self.astute_yaml_name)
  end

  def self.globlas_prefix
    'globals_yaml_for_'
  end

  def self.hiera_data_astute
    self.astute_yaml_name.gsub(/.yaml$/, '')
  end

  def self.hiera_data_globals
    self.globlas_prefix + self.hiera_data_astute
  end

  def self.hiera_config_file
    File.join self.fixtures_path, 'hiera.yaml'
  end

  def self.fuel_settings
    YAML.load_file self.astute_yaml_path
  end

  def self.fqdn
    self.fuel_settings['fqdn']
  end

  def self.hostname
    self.fqdn.split('.').first
  end

  def self.node_hash
    Noop.fuel_settings['nodes'].find { |node| node['fqdn'] == Noop.fqdn } || {}
  end

  def self.manifest_present?(manifest)
    manifest_path = File.join self.modular_manifests_node_dir, manifest
    self.fuel_settings['tasks'].find do |task|
      task['parameters']['puppet_manifest'] == manifest_path
    end
  end

  def self.ubuntu_facts
    {
        :fqdn                 => self.fqdn,
        :hostname             => self.hostname,
        :processorcount       => '4',
        :memorysize_mb        => '32138.66',
        :memorysize           => '31.39 GB',
        :kernel               => 'Linux',
        :osfamily             => 'Debian',
        :operatingsystem      => 'Ubuntu',
        :operatingsystemrelease => '14.04',
        :lsbdistid            => 'Ubuntu',
        :l3_fqdn_hostname     => self.hostname,
        :l3_default_route     => '172.16.1.1',
        :concat_basedir       => '/tmp/',
        :hiera_data_path      => self.hiera_data_path,
        :hiera_data_globals   => self.hiera_data_globals,
        :hiera_data_astute    => self.hiera_data_astute,
        :hiera_config_file    => self.hiera_config_file,
    }
  end

  def self.centos_facts
    {
        :fqdn                 => self.fqdn,
        :hostname             => self.hostname,
        :processorcount       => '4',
        :memorysize_mb        => '32138.66',
        :memorysize           => '31.39 GB',
        :kernel               => 'Linux',
        :osfamily             => 'RedHat',
        :operatingsystem      => 'CentOS',
        :operatingsystemrelease => '6.5',
        :lsbdistid            => 'CentOS',
        :l3_fqdn_hostname     => self.hostname,
        :l3_default_route     => '172.16.1.1',
        :concat_basedir       => '/tmp/',
        :hiera_data_path      => self.hiera_data_path,
        :hiera_data_globals   => self.hiera_data_globals,
        :hiera_data_astute    => self.hiera_data_astute,
        :hiera_config_file    => self.hiera_config_file,
    }
  end

  def self.modular_manifests_node_dir
    '/etc/puppet/modules/osnailyfacter/modular'
  end

  def self.modular_manifests_local_dir
    File.join self.module_path, 'osnailyfacter/modular'
  end

  def self.set_manifest(manifest)
      RSpec.configuration.manifest = File.join self.modular_manifests_local_dir, manifest
  end

end

# Add fixture lib dirs to LOAD_PATH. Work-around for PUP-3336
if Puppet.version < '4.0.0'
  Dir["#{Noop.module_path}/*/lib"].entries.each do |lib_dir|
    $LOAD_PATH << lib_dir
  end
end

RSpec.configure do |c|
  c.module_path = Noop.module_path
  c.hiera_config = Noop.hiera_config_file
  c.expose_current_running_example_as :example

  c.pattern = 'hosts/**'

  c.before :each do |test|
    # avoid "Only root can execute commands as other users"
    Puppet.features.stubs(:root? => true)
    # clear cached facts
    Facter::Util::Loader.any_instance.stubs(:load_all)
    Facter.clear
    Facter.clear_messages
    # Puppet logs creation
    if puppet_logs_dir != 'none'
      descr = test.metadata[:example_group][:full_description].gsub(/\s+|\//, '_').gsub(/\(|\)/, '')
      @file = "#{puppet_logs_dir}/#{descr}.log"
      Puppet::Util::Log.newdestination(@file)
      Puppet::Util::Log.level = :debug
    end
  end

  c.after :each do |test|
    # Puppet logs cleanup
    if puppet_logs_dir != 'none'
      Puppet::Util::Log.close_all
      descr = test.metadata[:example_group][:full_description].gsub(/\s+|\//, '_').gsub(/\(|\)|/, '')
      if example.exception == nil
        # Remove puppet log if there are no compilation errors
        File.delete("#{puppet_logs_dir}/#{descr}.log")
      end
    end
  end

end

