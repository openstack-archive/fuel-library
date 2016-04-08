require 'spec_helper'

describe Puppet::Type.type(:hiera_config).provider(:ruby) do
  let(:params) do
    {
        :name => '/etc/hiera.yaml',
        :hierarchy => %w(base additional),
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
            :datadir => "/etc/hiera",
        },
        :hierarchy => %w(plugins/a plugins/b plugins/c additional base),
        :backends => ["yaml"],
        :logger => "noop",
        :merge_behavior => 'deeper',
    }
  end

  let(:config_file_data_for_metadata_entries) do
    {
        :yaml => {
            :datadir => "/etc/hiera",
        },
        :hierarchy => %w(plugins/plugin1 plugins/plugin2 additional base),
        :backends => ["yaml"],
        :logger => "noop",
        :merge_behavior => 'deeper',
    }
  end

  let(:property_hash) do
    {
        :logger => "noop",
        :data_dir => "/etc/hiera",
        :hierarchy => %w(additional base),
        :hierarchy_override => %w(plugins/a plugins/b plugins/c),
        :merge_behavior => 'deeper',
    }
  end

  let(:override_dir) do
    '/etc/hiera/plugins'
  end

  let(:hierarchy_override) do
    %w(plugins/a plugins/b plugins/c)
  end

  let(:plugin_metadata_structure) do
    {
        'plugin1' => {
            'metadata' => {
            },
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

  let(:metadata_plugins_list) do
    %w(plugins/plugin1 plugins/plugin2)
  end

  before(:each) do
    provider.stubs(:yaml_load_file).with('/etc/hiera.yaml').returns(config_file_data)
    provider.stubs(:yaml_load_file).with('/etc/astute.yaml').returns(plugin_metadata_structure)
    provider.stubs(:yaml_load_file).with(nil).returns(nil)
    provider.stubs(:dir_entries).with(override_dir).returns %w(a.yaml c.yaml b.yaml . .. 1.txt test)
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

    it 'can form the full override directory path' do
      expect(provider.override_dir_path).to eq override_dir
    end

    it 'can get the list of found override elements' do
      expect(provider.override_directory_entries).to eq hierarchy_override
    end

    it 'can get the list of elements from the metadata file' do
      resource[:metadata_yaml_file] = '/etc/astute.yaml'
      expect(provider.metadata_plugin_entries).to eq metadata_plugins_list
    end

    it 'will use metadata entries prior to directory entries' do
      resource[:metadata_yaml_file] = '/etc/astute.yaml'
      expect(provider.generate_override_entries).to eq metadata_plugins_list
    end

    it 'will use directory entries if there are is metadata file' do
      resource[:metadata_yaml_file] = '/etc/astute.yaml'
      expect(provider.generate_override_entries).to eq metadata_plugins_list
    end

    it 'overwrites the hiera_override property with found values' do
      provider.load_configuration
      expect(resource[:hierarchy_override]).to eq hierarchy_override
    end

    it 'will not rewrite the hiera_override property if it contains any data from catalog' do
      resource[:hierarchy_override] = %w(a b)
      provider.load_configuration
      expect(resource[:hierarchy_override]).to eq %w(a b)
    end

  end

  context '#generate' do
    before(:each) do
      provider.property_hash = property_hash
    end

    it 'can generate the hierarchy structure' do
      expect(provider.generate_hierarhy).to eq config_file_data[:hierarchy]
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

    it 'will save any additional parameters in the Hiera config file' do
      provider.stubs(:read_configuration).returns(config_file_data.merge(:a => 1))
      provider.load_configuration
      provider.expects(:write_configuration).with(config_file_data.merge(:a => 1))
      provider.flush
    end
  end

  context '#both retreive and generate' do
    it 'cat generate configuration with directory entries' do
      provider.load_configuration
      provider.hierarchy_override = resource[:hierarchy_override]
      expect(provider.generate_configuration).to eq(config_file_data)
    end

    it 'cat generate configuration with metadata entries' do
      resource[:metadata_yaml_file] = '/etc/astute.yaml'
      provider.load_configuration
      provider.hierarchy_override = resource[:hierarchy_override]
      expect(provider.generate_configuration).to eq(config_file_data_for_metadata_entries)
    end
  end

end
