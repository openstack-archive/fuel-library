require 'rubygems'
require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'yaml'

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

  def self.facts
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

  # def self.hiera_config
  #   {
  #       :backends => ['yaml'],
  #       :hierarchy => [
  #           self.hiera_data_globals,
  #           self.hiera_data_astute,
  #       ],
  #       :yaml => {
  #           :datadir => self.hiera_data_path,
  #       }
  #   }
  # end

  def self.set_manifest(manifest)
      RSpec.configuration.manifest = File.join self.module_path, 'osnailyfacter/modular', manifest
  end

end

RSpec.configure do |c|
  c.module_path = Noop.module_path
  c.hiera_config = Noop.hiera_config_file

  c.pattern = 'hosts/**'

  c.before :each do
    # avoid "Only root can execute commands as other users"
    Puppet.features.stubs(:root? => true)
    # clear cached facts
    Facter::Util::Loader.any_instance.stubs(:load_all)
    Facter.clear
    Facter.clear_messages
  end
end


