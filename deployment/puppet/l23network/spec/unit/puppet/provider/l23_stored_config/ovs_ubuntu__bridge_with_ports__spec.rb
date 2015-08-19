require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:l23_stored_config).provider(:ovs_ubuntu) do

  let(:input_data) do
    {
      :br8 => {
        :name           => 'br8',
        :bridge_ports   => ['ttt1', 'ttt0'],
        :ensure         => 'present',
        :if_type        => 'bridge',
        :onboot         => true,
        :method         => 'manual',
        :provider       => "ovs_ubuntu",
      },
    }
  end

  let(:resources) do
    resources = {}
    input_data.each do |name, res|
      resources.store name, Puppet::Type.type(:l23_stored_config).new(res)
    end
    return resources
  end

  let(:providers) do
    providers = {}
    resources.each do |name, resource|
      provider = resource.provider
      if ENV['SPEC_PUPPET_DEBUG']
        class << provider
          def debug(msg)
            puts msg
          end
        end
      end
      provider.create
      providers.store name, provider
    end
    providers
  end

  before(:each) do
    if ENV['SPEC_PUPPET_DEBUG']
      Puppet::Util::Log.level = :debug
      Puppet::Util::Log.newdestination(:console)
    end
  end

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'ovs_ubuntu__spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  # context "the method property" do
  #   context 'when dhcp' do
  #     let(:data) { subject.class.parse_file('eth0', fixture_data('ifcfg-eth0'))[0] }
  #     it { expect(data[:method]).to eq :dhcp }
  #   end
  # end

  context "standalone OVS bridge" do

    context 'format file' do
      subject { providers[:br8] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+br8/) }
      it { expect(cfg_file).to match(/allow-ovs\s+br8/) }
      it { expect(cfg_file).to match(/iface\s+br8\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/ovs_type\s+OVSBridge/) }
      it { expect(cfg_file).to match(/ovs_ports\s+ttt0\s+ttt1/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(5) }  #  no more lines in the interface file
    end

    context "parse data from fixture" do
      let(:res) { subject.class.parse_file('br8', fixture_data('ifcfg-bridge-with-ports'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:name]).to eq 'br8' }
      it { expect(res[:bridge_ports]).to eq ['ttt0', 'ttt1'] }
      it { expect(res[:if_type].to_s).to eq 'bridge' }
      it { expect(res[:if_provider].to_s).to eq 'ovs' }
    end

  end

end
