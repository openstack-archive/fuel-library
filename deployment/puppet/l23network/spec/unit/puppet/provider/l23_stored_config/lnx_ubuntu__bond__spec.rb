require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_ubuntu) do

  let(:input_data) do
    {
      :bond0 => {
        :name           => 'bond0',
        :ensure         => 'present',
        :if_type        => 'bond',
        :mtu            => '9000',
        :onboot         => true,
        :method         => 'manual',
        :bond_mode      => '802.3ad',
        :bond_xmit_hash_policy => 'encap3+4',
        :bond_slaves    => ['eth2', 'eth3'],
        :bond_miimon    => '50',
        :bond_lacp_rate => 'fast',
        :provider       => "lnx_ubuntu",
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
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'lnx_ubuntu__spec')
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

  context "OVS bond with two interfaces" do

    context 'format file' do
      subject { providers[:bond0] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+bond0/) }
      it { expect(cfg_file).to match(/iface\s+bond0\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/mtu\s+9000/) }
      it { expect(cfg_file).to match(/bond-slaves\s+eth2\s+eth3/) }
      it { expect(cfg_file).to match(/bond-lacp-rate\s+fast/) }
      it { expect(cfg_file).to match(/bond-mode\s+802\.3ad/) }
      it { expect(cfg_file).to match(/bond-miimon\s+50/) }
      it { expect(cfg_file).to match(/bond-xmit-hash-policy\s+encap3\+4/) }
    end

    context "parse data from fixture" do
      let(:res) { subject.class.parse_file('bond_0', fixture_data('ifcfg-bond0'))[0] }

      it { expect(res[:method]).to eq :manual }
      it { expect(res[:mtu]).to eq '9000' }
      it { expect(res[:if_type].to_s).to eq 'bond' }
      it { expect(res[:if_provider].to_s).to eq 'lnx' }
      it { expect(res[:bond_mode]).to eq '802.3ad' }
      it { expect(res[:bond_miimon]).to eq '50' }
      it { expect(res[:bond_lacp_rate]).to eq 'fast' }
      it { expect(res[:bond_lacp]).to eq '' }
      it { expect(res[:bond_slaves]).to eq ['eth2', 'eth3'] }
      it { expect(res[:bond_xmit_hash_policy]).to eq 'encap3+4' }
    end

  end

end
