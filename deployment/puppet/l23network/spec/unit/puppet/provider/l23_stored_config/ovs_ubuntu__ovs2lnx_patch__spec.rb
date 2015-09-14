require 'spec_helper'

resources_map =     {
      :'br-ovs' => {
                 :name     => "br-ovs",
                 :onboot   => "yes",
                 :if_type  => "bridge",
                 :bridge_ports => ['p_33470efd-0'], # in real cases this value doesn't pass directly to stored_config,
                 :provider     => "ovs_ubuntu",     # but filled in generate() method of type
               },
      :'br1' => {
                 :name     => "br1",
                 :onboot   => "yes",
                 :method   => "static",
                 :if_type  => "bridge",
                 :ipaddr   => "192.168.88.2/24",
                 :bridge_ports => ['p_33470efd-0'], # in real cases this value doesn't pass directly to stored_config,
                 :provider     => "lnx_ubuntu",     # but filled in generate() method of type
               },
      :'p_33470efd-0' => {
                 :name     => "p_33470efd-0",
                 :if_type  => "ethernet",
                 :bridge   => ["br-ovs", "br1"],
                 :jacks    => ['p_33470efd-0', 'p_33470efd-1'],
                 :provider => "ovs_ubuntu",
               },
}

# This test is functional continue of .spec/classes/ovs2lnx_patch__spec.rb
describe Puppet::Type.type(:l23_stored_config).provider(:ovs_ubuntu) do

  let(:input_data) { resources_map}

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
    return providers
  end

  before(:each) do
    if ENV['SPEC_PUPPET_DEBUG']
      Puppet::Util::Log.level = :debug
      Puppet::Util::Log.newdestination(:console)
    end
  end

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'ovs_ubuntu__ovs2lnx_patch__spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "when formating config files" do

    context 'for OVS bridge br-ovs' do
      subject { providers[:'br-ovs'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+br-ovs/) }
      it { expect(cfg_file).to match(/allow-ovs\s+br-ovs/) }
      it { expect(cfg_file).to match(/iface\s+br-ovs\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/ovs_type\s+OVSBridge/) }
      it { expect(cfg_file).to match(/ovs_ports\s+p_33470efd-0/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(5) }
    end

    context 'for LNX bridge br1' do
      subject { providers[:'br1'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+br1/) }
      it { expect(cfg_file).to match(/iface\s+br1\s+inet\s+static/) }
      it { expect(cfg_file).to match(/bridge_ports\s+p_33470efd-0/) }
      it { expect(cfg_file).to match(/address\s+192.168.88.2\/24/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(4) }
    end

    context 'for ovs2lnx patchcord p_33470efd-0' do
      subject { providers[:'p_33470efd-0'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+p_33470efd-0/) }
      it { expect(cfg_file).to match(/allow-br-ovs\s+p_33470efd-0/) }
      it { expect(cfg_file).to match(/iface\s+p_33470efd-0\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/ovs_type\s+OVSIntPort/) }
      it { expect(cfg_file).to match(/ovs_bridge\s+br-ovs/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(5) }
    end
  end

  context "when parsing config files" do

    context 'for OVS bridge br-ovs' do
     #let(:res) { subject.class.parse_file('bond_lacp', fixture_data('ifcfg-port'))[0] }

      #let(:res) { subject.class.parse_file('br-ovs', fixture_data('ifcfg-br-ovs'))[0] }
      let(:res) { subject.class.parse_file('br-ovs', fixture_data('ifcfg-br-ovs'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'br-ovs' }
      it { expect(res[:bridge_ports]).to eq ['p_33470efd-0'] }
      it { expect(res[:if_type].to_s).to eq 'bridge' }
      it { expect(res[:if_provider].to_s).to eq 'ovs' }
    end

    #context 'for LNX bridge br1' do
      # see below, because lnx_ubuntu provider should be used
    #end

    context 'for ovs2lnx patchcord p_33470efd-0' do
      let(:res) { subject.class.parse_file('p_33470efd-0', fixture_data('ifcfg-p_33470efd-0'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'p_33470efd-0' }
      it { expect(res[:bridge]).to eq "br-ovs" }
      it { expect(res[:if_type].to_s).to eq 'ethernet' }
      it { expect(res[:if_provider].to_s).to eq 'ovs' }
    end
  end

end

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_ubuntu) do

  let(:input_data) { resources_map}

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
    return providers
  end

  before(:each) do
    if ENV['SPEC_PUPPET_DEBUG']
      Puppet::Util::Log.level = :debug
      Puppet::Util::Log.newdestination(:console)
    end
  end

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'ovs_ubuntu__ovs2lnx_patch__spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "when parsing config files" do
      let(:res) { subject.class.parse_file('br1', fixture_data('ifcfg-br1'))[0] }
      it { expect(res[:method]).to eq :static }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'br1' }
      it { expect(res[:bridge_ports]).to eq ['p_33470efd-0'] }
      it { expect(res[:if_provider].to_s).to eq 'lnx' }
  end
end