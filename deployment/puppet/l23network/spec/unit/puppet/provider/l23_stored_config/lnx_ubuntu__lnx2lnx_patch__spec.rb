require 'spec_helper'

resources_map =     {
      :'br1' => {
        :name     => "br1",
        :onboot   => "yes",
        :method   => "static",
        :if_type  => "bridge",
        :ipaddr   => "192.168.88.2/24",
        :bridge_ports => ['p_33470efd-0'], # in real cases this value doesn't pass directly to stored_config,
        :provider     => "lnx_ubuntu",     # but filled in generate() method of type
      },
      :'br2' => {
        :name     => "br2",
        :onboot   => "yes",
        :method   => "static",
        :if_type  => "bridge",
        :ipaddr   => "192.168.99.2/24",
        :bridge_ports => ['p_33470efd-1'], # in real cases this value doesn't pass directly to stored_config,
        :provider     => "lnx_ubuntu",     # but filled in generate() method of type
      },
      :'p_33470efd-0' => {
        :name     => 'p_33470efd-0',
        :if_type  => 'patch',
        :bridge   => ["br1"],
        :jacks    => ['p_33470efd-0', 'p_33470efd-1'],
        :provider => "lnx_ubuntu",
      },
      :'p_33470efd-1' => {
        :name     => "p_33470efd-1",
        :if_type  => 'patch',
        :bridge   => ["br2"],
        :jacks    => ['p_33470efd-0', 'p_33470efd-1'],
        :provider => "lnx_ubuntu",
      },
      :'p_33470efd-1_mtu' => {
        :name     => "p_33470efd-1",
        :if_type  => 'patch',
        :mtu      => 1700,
        :bridge   => ["br2"],
        :jacks    => ['p_33470efd-0', 'p_33470efd-1'],
        :provider => "lnx_ubuntu",
      },

}

# This test is functional continue of .spec/classes/ovs2lnx_patch__spec.rb
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
    puppet_debug_override()
  end

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'lnx_ubuntu__lnx2lnx_patch__spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "when formating config files" do

    context 'for LNX bridge br1' do
      subject { providers[:'br1'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+br1/) }
      it { expect(cfg_file).to match(/iface\s+br1\s+inet\s+static/) }
      it { expect(cfg_file).to match(/bridge_ports\s+p_33470efd-0/) }
      it { expect(cfg_file).to match(/address\s+192.168.88.2\/24/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(4) }
    end

    context 'for LNX bridge br2' do
      subject { providers[:'br2'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+br2/) }
      it { expect(cfg_file).to match(/iface\s+br2\s+inet\s+static/) }
      it { expect(cfg_file).to match(/bridge_ports\s+p_33470efd-1/) }
      it { expect(cfg_file).to match(/address\s+192.168.99.2\/24/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(4) }
    end

    context 'for lnx2lnx patchcord p_33470efd-0' do
      subject { providers[:'p_33470efd-0'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+p_33470efd-0/) }
      it { expect(cfg_file).to match(/iface\s+p_33470efd-0\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/pre-up\s+ip\s+link\s+add\s+p_33470efd-0\s+mtu\s+1500\s+type\s+veth\s+peer\s+name\s+p_33470efd-1\s+mtu\s+1500/) }
      it { expect(cfg_file).to match(/post-up\s+ip\s+link\s+set\s+up\s+dev\s+p_33470efd-1/) }
      it { expect(cfg_file).to match(/post-down\s+ip\s+link\s+del\s+p_33470efd-0/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(5) }
    end

    context 'for lnx2lnx patchcord p_33470efd-1' do
      subject { providers[:'p_33470efd-1'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+p_33470efd-1/) }
      it { expect(cfg_file).to match(/iface\s+p_33470efd-1\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/pre-up\s+ip\s+link\s+add\s+p_33470efd-0\s+mtu\s+1500\s+type\s+veth\s+peer\s+name\s+p_33470efd-1\s+mtu\s+1500/) }
      it { expect(cfg_file).to match(/post-up\s+ip\s+link\s+set\s+up\s+dev\s+p_33470efd-1/) }
      it { expect(cfg_file).to match(/post-down\s+ip\s+link\s+del\s+p_33470efd-0/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(5) }
    end

    context 'for lnx2lnx patchcord p_33470efd-1 mtu 1700' do
      subject { providers[:'p_33470efd-1_mtu'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+p_33470efd-1/) }
      it { expect(cfg_file).to match(/iface\s+p_33470efd-1\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/mtu\s+1700/) }
      it { expect(cfg_file).to match(/pre-up\s+ip\s+link\s+add\s+p_33470efd-0\s+mtu\s+1700\s+type\s+veth\s+peer\s+name\s+p_33470efd-1\s+mtu\s+1700/) }
      it { expect(cfg_file).to match(/post-up\s+ip\s+link\s+set\s+up\s+dev\s+p_33470efd-1/) }
      it { expect(cfg_file).to match(/post-down\s+ip\s+link\s+del\s+p_33470efd-0/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(6) }
    end


  end

  context "when parsing config files" do

    context 'for LNX bridge br1' do
      let(:res) { subject.class.parse_file('br1', fixture_data('ifcfg-br1'))[0] }
      it { expect(res[:method]).to eq :static }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'br1' }
      it { expect(res[:bridge_ports]).to eq ['p_33470efd-0'] }
      it { expect(res[:if_type].to_s).to eq 'bridge' }
      it { expect(res[:if_provider].to_s).to eq 'lnx' }
    end

    context 'for LNX bridge br2' do
      let(:res) { subject.class.parse_file('br2', fixture_data('ifcfg-br2'))[0] }
      it { expect(res[:method]).to eq :static }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'br2' }
      it { expect(res[:bridge_ports]).to eq ['p_33470efd-1'] }
      it { expect(res[:if_type].to_s).to eq 'bridge' }
      it { expect(res[:if_provider].to_s).to eq 'lnx' }
    end

    context 'for lnx2lnx patchcord p_33470efd-0' do
      let(:res) { subject.class.parse_file('p_33470efd-0', fixture_data('ifcfg-p_33470efd-0'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'p_33470efd-0' }
      it { expect(res[:if_type].to_s).to eq 'patch' }
      it { expect(res[:if_provider].to_s).to eq 'lnx' }
    end

    context 'for lnx2lnx patchcord p_33470efd-1' do
      let(:res) { subject.class.parse_file('p_33470efd-1', fixture_data('ifcfg-p_33470efd-1'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'p_33470efd-1' }
      it { expect(res[:if_type].to_s).to eq 'patch' }
      it { expect(res[:if_provider].to_s).to eq 'lnx' }
    end

  end

end
