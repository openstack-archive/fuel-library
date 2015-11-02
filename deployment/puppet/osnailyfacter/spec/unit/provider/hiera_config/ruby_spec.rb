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
        :hierarchy => %w(plugins/c plugins/b plugins/a additional base),
        :backends => ["yaml"],
        :logger => "noop",
        :merge_behavior => 'deeper',
    }
  end

  let(:property_hash) do
    {
        :logger => "noop",
        :data_dir => "/etc/hiera",
        :hierarchy => %w(base additional),
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


  before(:each) do
    allow(provider).to receive(:yaml_load_file).with('/etc/hiera.yaml').and_return(config_file_data)
    allow(provider).to receive(:dir_entries).with(override_dir).and_return %w(a.yaml c.yaml b.yaml . .. 1.txt test)
  end

  context '#retreive' do

    it 'can read the Hiera config file file' do
      expect(provider.read_configuration).to eq config_file_data
    end

    it 'returns an empty hash if file was not read' do
      expect(provider).to receive(:yaml_load_file).with('/etc/hiera.yaml').and_raise(Errno::ENOENT)
      expect(provider.read_configuration).to eq({})
    end

    it 'parses the retrieved data to the property_hash' do
      expect(provider.load_configuration).to eq property_hash
      expect(provider.property_hash).to eq property_hash
    end

    it 'can form the full override directory path' do
      expect(provider.override_dir_path).to eq override_dir
    end

    it 'can ret the list of found override elements' do
      expect(provider.override_dir_entries).to eq hierarchy_override
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

  context '#set' do
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
      allow(provider).to receive(:read_configuration).and_return({})
      expect(provider).to receive(:write_configuration).with(config_file_data)
      provider.flush
    end

    it 'can set a value and set it in the configuration file' do
      allow(provider).to receive(:read_configuration).and_return config_file_data
      provider.logger = 'console'
      expect(provider).to receive(:write_configuration).with(config_file_data.merge(:logger => 'console'))
      provider.flush
    end

    it 'will save any additional parameters in the Hiera config file' do
      allow(provider).to receive(:read_configuration).and_return config_file_data.merge(:a => 1)
      provider.load_configuration
      expect(provider).to receive(:write_configuration).with(config_file_data.merge(:a => 1))
      provider.flush
    end
  end

end
