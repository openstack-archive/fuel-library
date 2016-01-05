require 'spec_helper'

resources_map =     {
      :'p2p1' => {
                 :name     => 'p2p1',
                 :if_type  => 'ethernet',
                 :bridge   => 'br-ovs1',
                 :vlan_id  => '100',
                 :provider => 'ovs_ubuntu',
               },
}

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
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'ubuntu_ports')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "formating config files" do

    context 'OVS port p2p1 ' do
      subject { providers[:'p2p1'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/allow-br-ovs1\s+p2p1/) }
      it { expect(cfg_file).to match(/iface\s+p2p1\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/ovs_type\s+OVSPort/) }
      it { expect(cfg_file).to match(/ovs_bridge\s+br-ovs1/) }
      it { expect(cfg_file).to match(/ovs_extra\s+--\s+set\s+Port\s+p2p1\st+ag=100/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(5) }
    end

  end

  context "parsing config files" do

    context 'OVS port p2p1' do
      let(:res) { subject.class.parse_file('p2p1', fixture_data('ifcfg-p2p1'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:name]).to eq 'p2p1' }
      it { expect(res[:bridge]).to eq "br-ovs1" }
      it { expect(res[:vlan_id]).to eq '100' }
      it { expect(res[:if_provider].to_s).to eq 'ovs' }
    end

  end

end
