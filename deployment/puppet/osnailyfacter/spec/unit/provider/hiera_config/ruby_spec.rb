require 'spec_helper'

describe Puppet::Type.type(:hiera_config).provider(:ruby) do
  let(:params) do
    {
        :path => '/etc/hiera.yaml',
        :hierarchy_top => %w(top1 top2),
        :hierarchy_bottom => %w(additional base),
        :merge_behavior => 'deeper',
        :additions => {
            'test' => '123',
        }
    }
  end

  let (:resource) do
    Puppet::Type::Hiera_config.new params
  end

  let (:provider) do
    resource.provider
  end

  before(:each) do
    puppet_debug_override
  end

  let(:config_file_data) do
    {
        :yaml => {
            :datadir => '/etc/hiera',
        },
        :hierarchy => %w(top1 top2 plugins/a plugins/b plugins/c additional base),
        :backends => ['yaml'],
        :logger => 'noop',
        :merge_behavior => 'deeper',
        :test => '123',
    }
  end

  let(:config_file_data_for_metadata_entries) do
    {
        :yaml => {
            :datadir => '/etc/hiera',
        },
        :hierarchy => %w(top1 top2 plugins/a plugins/b plugins/c plugins/plugin1 plugins/plugin2 plugins/l1 plugins/l2 plugins/l3 additional base),
        :backends => ['yaml'],
        :logger => 'noop',
        :merge_behavior => 'deeper',
        :test => '123',
    }
  end

  let(:property_hash) do
    {
        :logger => 'noop',
        :backends => ['yaml'],
        :data_dir => '/etc/hiera',
        :hierarchy_top => %w(top1 top2),
        :hierarchy_plugins => %w(plugins/a plugins/b plugins/c),
        :hierarchy_bottom => %w(additional base),
        :merge_behavior => 'deeper',
        :additions => {
            :test => '123',
        },
    }
  end

  let(:plugins_dir_path) do
    '/etc/hiera/plugins'
  end

  let(:plugin_metadata_structure) do
    {
        'plugin1' => {
            'metadata' => {
                'hiera' => ['l3'],
            },
            'hiera' => 'l2',
        },
        'plugin2' => {
            'metadata' => {
            },
        },
        'a' => 'b',
        'c' => {
            'metadata' => 'd'
        },
        'plugins' => [
            {
                'name' => 'plugin1',
                'hiera' => 'l1',
            },
            {
                'name' => 'plugin2',
            },
            {
                'type' => 'bad_plugin',
            }
        ],
    }
  end

  let(:reported_plugins_list) do
    %w(plugins/l1 plugins/l2 plugins/l3)
  end

  let(:metadata_plugins_list) do
    %w(plugins/plugin1 plugins/plugin2)
  end

  let(:hierarchy_plugins) do
    %w(plugins/a plugins/b plugins/c)
  end

  let(:all_plugins_list) do
    hierarchy_plugins + metadata_plugins_list + reported_plugins_list
  end

  before(:each) do
    provider.stubs(:yaml_load_file).with('/etc/hiera.yaml').returns(config_file_data)
    provider.stubs(:yaml_load_file).with('/etc/astute.yaml').returns(plugin_metadata_structure)
    provider.stubs(:yaml_load_file).with(nil).returns(nil)
    provider.stubs(:dir_entries).with(plugins_dir_path).returns %w(a.yaml c.yaml b.yaml . .. 1.txt test)
  end

  context '#retreive' do

    it 'can read the Hiera config file file' do
      expect(provider.read_configuration).to eq config_file_data
    end

    it 'returns an empty hash if file was not read' do
      provider.expects(:yaml_load_file).with('/etc/hiera.yaml').raises(Errno::ENOENT)
      expect(provider.read_configuration).to eq({})
    end

    it 'parses the retrieved data to the property_hash' do
      expect(provider.load_configuration).to eq property_hash
      expect(provider.property_hash).to eq property_hash
    end

    it 'parses the retrieved data to the property_hash if there is no plugins' do
      no_plugins_config_file_data = config_file_data
      no_plugins_config_file_data[:hierarchy] = %w(top1 top2 plugins_placeholder additional base)
      no_plugins_property_hash = property_hash
      no_plugins_property_hash[:hierarchy_plugins] = ['plugins_placeholder']
      provider.stubs(:yaml_load_file).with('/etc/hiera.yaml').returns(no_plugins_config_file_data)
      expect(provider.load_configuration).to eq no_plugins_property_hash
      expect(provider.property_hash).to eq no_plugins_property_hash
    end

    it 'can form the full plugins directory path' do
      expect(provider.plugins_dir_path).to eq plugins_dir_path
    end

    it 'can get the list of directory plugin elements' do
      expect(provider.directory_plugin_entries).to eq hierarchy_plugins
    end

    it 'can get the list of enabled plugin elements' do
      resource[:metadata_yaml_file] = '/etc/astute.yaml'
      expect(provider.enabled_plugin_entries).to eq metadata_plugins_list
    end

    it 'can get the elements listed in the plugin settings and metadata' do
      resource[:metadata_yaml_file] = '/etc/astute.yaml'
      expect(provider.reported_plugin_entries).to eq reported_plugins_list
    end

    it 'can return a placeholder if there are no plugins' do
      provider.stubs(:dir_entries).with(plugins_dir_path).returns %w(. ..)
      expect(provider.generate_plugins_entries).to eq ['plugins_placeholder']
    end

    it 'will use all available entries' do
      resource[:metadata_yaml_file] = '/etc/astute.yaml'
      expect(provider.generate_plugins_entries).to eq all_plugins_list
    end

    it 'can add a special suffix to all elements' do
      resource[:override_suffix] = '_test'
      resource[:metadata_yaml_file] = '/etc/astute.yaml'
      expect(provider.generate_plugins_entries).to eq(all_plugins_list.map { |e| e + '_test' })
    end

    it 'overwrites the hierarchy_plugins property with found values' do
      provider.load_configuration
      expect(resource[:hierarchy_plugins]).to eq hierarchy_plugins
    end

    it 'will not rewrite the hierarchy_plugins property if it contains any data from catalog' do
      resource[:hierarchy_plugins] = %w(a b)
      provider.load_configuration
      expect(resource[:hierarchy_plugins]).to eq %w(a b)
    end

  end

  context '#generate' do
    before(:each) do
      provider.property_hash = property_hash
    end

    it 'can generate the hierarchy structure' do
      expect(provider.generate_hierarchy).to eq config_file_data[:hierarchy]
    end

    it 'can generate a new configuration structure from the property_hash' do
      expect(provider.generate_configuration).to eq config_file_data
    end

    it 'can create a new configuration if there is no saved one' do
      provider.stubs(:read_configuration).returns({})
      provider.expects(:write_configuration).with(config_file_data)
      provider.flush
    end

    it 'can set a value and set it in the configuration file' do
      provider.stubs(:read_configuration).returns(config_file_data)
      provider.logger = 'console'
      provider.expects(:write_configuration).with(config_file_data.merge(:logger => 'console'))
      provider.flush
    end

    it 'can create a new configuration file' do
      provider.stubs(:enabled_plugin_entries).returns(hierarchy_plugins)
      provider.stubs(:read_configuration).returns({})
      provider.exists?
      provider.create
      provider.expects(:write_configuration).with(config_file_data)
      provider.flush
    end
  end

  context '#both retrieve and generate' do
    it 'cat generate configuration with directory entries' do
      provider.load_configuration
      provider.hierarchy_plugins = resource[:hierarchy_plugins]
      expect(provider.generate_configuration).to eq(config_file_data)
    end

    it 'cat generate configuration with metadata entries' do
      resource[:metadata_yaml_file] = '/etc/astute.yaml'
      provider.load_configuration
      provider.hierarchy_plugins = resource[:hierarchy_plugins]
      expect(provider.generate_configuration).to eq(config_file_data_for_metadata_entries)
    end
  end

end
