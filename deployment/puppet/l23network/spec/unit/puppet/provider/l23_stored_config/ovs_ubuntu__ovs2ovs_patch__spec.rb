require 'spec_helper'

resources_map =     {
      :'br-ovs1' => {
                 :name     => "br-ovs1",
                 :onboot   => "yes",
                 :if_type  => "bridge",
                 :bridge_ports => ['p_33470efd-0'],
                 :provider     => "ovs_ubuntu",
               },
      :'br-ovs2' => {
                 :name     => "br-ovs2",
                 :onboot   => "yes",
                 :method   => "static",
                 :if_type  => "bridge",
                 :ipaddr   => "192.168.88.2/24",
                 :bridge_ports => ['p_33470efd-0'],
                 :provider     => "lnx_ubuntu",
               },
      :'p_33470efd-0' => {
                 :name     => "p_33470efd-0",
                 :if_type  => "patch",
                 :bridge   => "br-ovs1",
                 :vlan_id  => '100',
                 :jacks    => 'p_33470efd-1',
                 :provider => "ovs_ubuntu",
               },
      :'p_33470efd-1' => {
                 :name     => "p_33470efd-1",
                 :if_type  => "patch",
                 :bridge   => "br-ovs2",
                 :vlan_id  => '200',
                 :jacks    => 'p_33470efd-0',
                 :provider => "ovs_ubuntu",
               },

}

# This test is functional continue of .spec/classes/ovs2ovs_patch__spec.rb
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
    puppet_debug_override()
  end

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'ovs_ubuntu__ovs2ovs_patch__spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "when formating config files" do

    context 'for OVS bridge br-ovs1' do
      subject { providers[:'br-ovs1'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+br-ovs1/) }
      it { expect(cfg_file).to match(/allow-ovs\s+br-ovs1/) }
      it { expect(cfg_file).to match(/iface\s+br-ovs1\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/ovs_type\s+OVSBridge/) }
      it { expect(cfg_file).to match(/ovs_ports\s+p_33470efd-0/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(5) }
    end

    context 'for OVS bridge br-ovs2' do
      subject { providers[:'br-ovs2'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+br-ovs2/) }
      it { expect(cfg_file).to match(/iface\s+br-ovs2\s+inet\s+static/) }
      it { expect(cfg_file).to match(/bridge_ports\s+p_33470efd-0/) }
      it { expect(cfg_file).to match(/address\s+192.168.88.2\/24/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(4) }
    end

    context 'for ovs2ovs patchcord p_33470efd-0' do
      subject { providers[:'p_33470efd-0'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+p_33470efd-0/) }
      it { expect(cfg_file).to match(/allow-br-ovs1\s+p_33470efd-0/) }
      it { expect(cfg_file).to match(/iface\s+p_33470efd-0\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/ovs_type\s+OVSPort/) }
      it { expect(cfg_file).to match(/ovs_bridge\s+br-ovs1/) }
      it { expect(cfg_file).to match(/ovs_extra\s+--\s+set\s+Interface\s+p_33470efd-0\s+type=patch\s+options:peer=p_33470efd-1/) }
      it { expect(cfg_file).to match(/ovs_extra\s+--\s+set\s+Port\s+p_33470efd-0\s+tag=100/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(7) }
    end

    context 'for ovs2ovs patchcord p_33470efd-1' do
      subject { providers[:'p_33470efd-1'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+p_33470efd-1/) }
      it { expect(cfg_file).to match(/allow-br-ovs2\s+p_33470efd-1/) }
      it { expect(cfg_file).to match(/iface\s+p_33470efd-1\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/ovs_type\s+OVSPort/) }
      it { expect(cfg_file).to match(/ovs_bridge\s+br-ovs2/) }
      it { expect(cfg_file).to match(/ovs_extra\s+--\s+set\s+Interface\s+p_33470efd-1\s+type=patch\s+options:peer=p_33470efd-0/) }
      it { expect(cfg_file).to match(/ovs_extra\s+--\s+set\s+Port\s+p_33470efd-1\s+tag=200/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(7) }
    end

  end

  context "when parsing config files" do

    context 'for OVS bridge br-ovs1' do

      let(:res) { subject.class.parse_file('br-ovs1', fixture_data('ifcfg-br-ovs1'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'br-ovs1' }
      it { expect(res[:bridge_ports]).to eq ['p_33470efd-0'] }
      it { expect(res[:if_type].to_s).to eq 'bridge' }
      it { expect(res[:if_provider].to_s).to eq 'ovs' }
    end

    context 'for OVS bridge br-ovs2' do

      let(:res) { subject.class.parse_file('br-ovs2', fixture_data('ifcfg-br-ovs2'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'br-ovs2' }
      it { expect(res[:bridge_ports]).to eq ['p_33470efd-1'] }
      it { expect(res[:if_type].to_s).to eq 'bridge' }
      it { expect(res[:if_provider].to_s).to eq 'ovs' }
    end


    context 'for ovs2ovs patchcord p_33470efd-0' do
      let(:res) { subject.class.parse_file('p_33470efd-0', fixture_data('ifcfg-p_33470efd-0'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'p_33470efd-0' }
      it { expect(res[:bridge]).to eq "br-ovs1" }
      it { expect(res[:vlan_id]).to eq '100' }
      it { expect(res[:jacks]).to eq ['p_33470efd-1'] }
      it { expect(res[:if_provider].to_s).to eq 'ovs' }
    end

    context 'for ovs2ovs patchcord p_33470efd-1' do
      let(:res) { subject.class.parse_file('p_33470efd-1', fixture_data('ifcfg-p_33470efd-1'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'p_33470efd-1' }
      it { expect(res[:bridge]).to eq "br-ovs2" }
      it { expect(res[:vlan_id]).to eq '200' }
      it { expect(res[:jacks]).to eq ['p_33470efd-0'] }
      it { expect(res[:if_provider].to_s).to eq 'ovs' }
    end

  end

end
