require 'rubygems'
require 'puppet'
require 'hiera_puppet'
require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'yaml'
require 'fileutils'
require 'find'

module Noop
  def self.module_path
    return @module_path if @module_path
    @module_path = File.expand_path(File.join(__FILE__, '..', '..', '..', '..', 'deployment', 'puppet'))
  end

  def self.hiera_data_path
    return ENV['SPEC_YAML_DIR'] if ENV['SPEC_YAML_DIR'] and File.directory? ENV['SPEC_YAML_DIR']
    return @hiera_data_path if @hiera_data_path
    @hiera_data_path = File.expand_path(File.join(__FILE__, '..', '..', 'astute.yaml'))
  end

  def self.fixtures_path
    return @fixtures_path if @fixtures_path
    @fixtures_path = File.expand_path(File.join(__FILE__, '..', '..', 'fixtures'))
  end

  def self.spec_path
    return @spec_path if @spec_path
    @spec_path = File.expand_path(File.join(__FILE__, '..', 'hosts'))
  end

  def self.astute_yaml_name
    ENV['SPEC_ASTUTE_FILE_NAME'] || 'novanet-primary-controller.yaml'
  end

  def self.puppet_logs_dir
    ENV['SPEC_PUPPET_LOGS_DIR']
  end

  def self.puppet_log_file
    name = manifest.gsub(/\s+|\//, '_').gsub(/\(|\)/, '') + '.log'
    File.join puppet_logs_dir, name
  end

  def self.astute_yaml_base
    File.basename(self.astute_yaml_name).gsub(/.yaml$/, '')
  end

  def self.astute_yaml_path
    File.expand_path File.join(self.hiera_data_path, self.astute_yaml_name)
  end

  def self.globals_yaml_path
    File.expand_path File.join(self.hiera_data_path, self.globlas_prefix + self.astute_yaml_name)
  end

  def self.tasks
    return @tasks if @tasks
    @tasks = []
    Find.find(self.module_path) do |file|
      next unless File.file? file
      next unless file.end_with? 'tasks.yaml'
      task = YAML.load_file(file)
      @tasks += task if task.is_a? Array
    end
    @tasks
  end

  def self.globlas_prefix
    'globals_yaml_for_'
  end

  def self.hiera_data_astute
    self.astute_yaml_base
  end

  def self.hiera_data_globals
    self.globlas_prefix + self.hiera_data_astute
  end

  def self.fqdn
    fqdn = hiera 'fqdn'
    raise 'Unable to get FQDN from Hiera!' unless fqdn
    fqdn
  end

  def self.role
    hiera 'role'
  end

  def self.hostname
    self.fqdn.split('.').first
  end

  def self.node_hash
    hiera('nodes').find { |node| node['fqdn'] == fqdn } || {}
  end

  def self.manifest_present?(manifest)
    manifest_path = File.join self.modular_manifests_node_dir, manifest
    tasks.each do |task|
      next unless task['type'] == 'puppet'
      next unless task['parameters']['puppet_manifest'] == manifest_path
      if task['role']
        return true if task['role'] == '*'
        return true if task['role'].include?(role)
      end
      if task['groups']
        return true if task['groups'] == '*'
        return true if task['groups'].include?(role)
      end
    end
    false
  end

  def self.hiera_config
    {
        :backends=> [
            'yaml',
        ],
        :yaml=>{
            :datadir => hiera_data_path,
        },
        :hierarchy=> [
            hiera_data_globals,
            hiera_data_astute,
        ],
        :logger => 'noop',
    }
  end

  def self.hiera_object
    Hiera.new(:config => hiera_config)
  end

  def self.hiera(key, default = nil)
    hiera_object.lookup key, default, {}
  end

  def self.hiera_structure(key, default=nil)
    path_lookup = lambda do |data, path, default_value|
      break default_value unless data
      break data unless path.is_a? Array and path.any?
      break default_value unless data.is_a? Hash or data.is_a? Array

      key = path.shift
      if data.is_a? Array
        begin
          key = Integer key
        rescue ArgumentError
          break default_value
        end
      end
      path_lookup.call data[key], path, default_value
    end

    path = key.split '/'
    key = path.shift
    data = hiera key
    path_lookup.call data, path, default
  end

  def self.hiera_puppet_override
    class << HieraPuppet
      def hiera
        Noop.hiera_object
      end
    end
  end

  def self.ubuntu_facts
    {
        :fqdn                 => fqdn,
        :hostname             => hostname,
        :processorcount       => '4',
        :memorysize_mb        => '32138.66',
        :memorysize           => '31.39 GB',
        :kernel               => 'Linux',
        :osfamily             => 'Debian',
        :operatingsystem      => 'Ubuntu',
        :operatingsystemrelease => '14.04',
        :lsbdistid            => 'Ubuntu',
        :l3_fqdn_hostname     => hostname,
        :l3_default_route     => '172.16.1.1',
        :concat_basedir       => '/tmp/',
        :l23_os               => 'ubuntu',
    }
  end

  def self.centos_facts
    {
        :fqdn                 => fqdn,
        :hostname             => hostname,
        :processorcount       => '4',
        :memorysize_mb        => '32138.66',
        :memorysize           => '31.39 GB',
        :kernel               => 'Linux',
        :osfamily             => 'RedHat',
        :operatingsystem      => 'CentOS',
        :operatingsystemrelease => '6.5',
        :lsbdistid            => 'CentOS',
        :l3_fqdn_hostname     => hostname,
        :l3_default_route     => '172.16.1.1',
        :concat_basedir       => '/tmp/',
        :l23_os               => 'centos6',
    }
  end

  def self.modular_manifests_node_dir
    '/etc/puppet/modules/osnailyfacter/modular'
  end

  def self.modular_manifests_local_dir
    File.join self.module_path, 'osnailyfacter/modular'
  end

  def self.manifest=(manifest)
    debug "Set manifest to: #{manifest} -> #{File.join self.modular_manifests_local_dir, manifest}"
    RSpec.configuration.manifest = File.join self.modular_manifests_local_dir, manifest
    @manifest = manifest
  end

  def self.manifest_path
    RSpec.configuration.manifest
  end

  def self.manifest
    @manifest
  end

  def self.test_ubuntu?
    return true unless ENV['SPEC_TEST_UBUNTU'] or ENV['SPEC_TEST_CENTOS']
    true if ENV['SPEC_TEST_UBUNTU']
  end

  def self.test_centos?
    return true unless ENV['SPEC_TEST_UBUNTU'] or ENV['SPEC_TEST_CENTOS']
    true if ENV['SPEC_TEST_CENTOS']
  end

  ## File resources list ##

  def self.file_resources_lists_dir
    File.expand_path File.join ENV['SPEC_SAVE_FILE_RESOURCES'], self.astute_yaml_base
  end

  def self.file_resources_list_file(manifest, os)
    file_name = manifest.gsub('/', '_').gsub('.pp', '') + "_#{os}_files.yaml"
    File.join file_resources_lists_dir, file_name
  end

  def self.save_file_resources_list(data, os)
    begin
      file_path = file_resources_list_file manifest, os
      FileUtils.mkdir_p file_resources_lists_dir unless File.directory? file_resources_lists_dir
      File.open(file_path, 'w') do |list_file|
        YAML.dump(data, list_file)
      end
    rescue
      puts "Could not save File resources list for manifest: '#{manifest}' to: '#{file_path}'"
    else
      puts "File resources list for manifest: '#{manifest}' saved to: '#{file_path}'"
    end
  end

  ## Package resources list ##

  def self.package_resources_lists_dir
    File.expand_path File.join ENV['SPEC_SAVE_PACKAGE_RESOURCES'], self.astute_yaml_base
  end

  def self.package_resources_list_file(manifest, os)
    file_name = manifest.gsub('/', '_').gsub('.pp', '') + "_#{os}_packages.yaml"
    File.join package_resources_lists_dir, file_name
  end

  def self.save_package_resources_list(data, os)
    begin
      file_path = package_resources_list_file manifest, os
      FileUtils.mkdir_p package_resources_lists_dir unless File.directory? package_resources_lists_dir
      File.open(file_path, 'w') do |list_file|
        YAML.dump(data, list_file)
      end
    rescue
      puts "Could not save Package resources list for manifest '#{manifest}' to '#{file_path}'"
    else
      puts "Package resources list for manifest '#{manifest}' saved to '#{file_path}'"
    end
  end

  def self.show_catalog(subject)
    catalog = subject
    catalog = subject.call if subject.is_a? Proc
    catalog.resources.each do |resource|
      puts '=' * 70
      puts resource.to_manifest
    end
  end

  def self.resource_test_template(binding)
    template = <<-'eof'
  it do
    expect(subject).to contain_<%= resource.type.gsub('::', '__').downcase %>('<%= resource.title %>').with(
<% max_length = resource.to_hash.keys.inject(0) { |ml, key| key = key.to_s; ml = key.size if key.size > ml; ml } -%>
<% resource.each do |parameter, value| -%>
      <%= ":#{parameter}".to_s.ljust(max_length + 1) %> => <%= value.inspect %>,
<% end -%>
    )
  end

    eof
    ERB.new(template, nil, '-').result(binding)
  end

  def self.catalog_to_spec(subject)
    catalog = subject
    catalog = subject.call if subject.is_a? Proc
    catalog.resources.each do |resource|
      next if %w(Stage Anchor).include? resource.type
      next if resource.type == 'Class' and %w(Settings main).include? resource.title.to_s
      puts resource_test_template binding
    end
  end

  def self.debug(msg)
    puts msg if ENV['SPEC_RSPEC_DEBUG']
  end

  def self.current_spec(example)
    example_group = lambda do |metdata|
      return example_group.call metdata[:example_group] if metdata[:example_group]
      return example_group.call metdata[:parent_example_group] if metdata[:parent_example_group]
      file_path = metdata[:absolute_file_path]
      file_path = file_path.gsub "#{spec_path}/", ''
      return file_path
    end
    example_group.call example.metadata
  end

  module Utils
    def self.filter_nodes(hash, name, value)
      hash.select do |it|
        it[name] == value
      end
    end

    def self.nodes_to_hash(hash, name, value)
      result = {}
      hash.each do |element|
        result[element[name]] = element[value]
      end
      result
    end

    def self.ipsort (ips)
      require 'rubygems'
      require 'ipaddr'
      ips.sort { |a,b| IPAddr.new( a ) <=> IPAddr.new( b ) }
    end
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
  c.expose_current_running_example_as :example

  c.pattern = 'hosts/**'

  c.before :each do
    # avoid "Only root can execute commands as other users"
    Puppet.features.stubs(:root? => true)
    # clear cached facts
    Facter::Util::Loader.any_instance.stubs(:load_all)
    Facter.clear
    Facter.clear_messages

    # Puppet logs creation
    if Noop.puppet_logs_dir
      Puppet::Util::Log.newdestination(Noop.puppet_log_file)
      Puppet::Util::Log.level = :debug
    end
  end

  c.after :each do
    # Puppet logs cleanup
    if Noop.puppet_logs_dir
      Puppet::Util::Log.close_all
      # Remove puppet log if there are no compilation errors
      unless example.exception
        File.unlink Noop.puppet_log_file if File.file? Noop.puppet_log_file
      end
    end
  end

  c.mock_with :rspec

end

Noop.hiera_puppet_override

