require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:l23_stored_config).provider(:ovs_ubuntu) do

  let(:input_data) do
    {
      :ttt0 => {
        :name           => 'ttt0',
        :ensure         => 'present',
        :bridge         => 'br9',
        :mtu            => '6000',
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
    puppet_debug_override()
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

  context "one OVS port, included to the OVS bridge" do

    context 'format file' do
      subject { providers[:ttt0] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+ttt0/) }
      it { expect(cfg_file).to match(/allow-br9\s+ttt0/) }
      it { expect(cfg_file).to match(/iface\s+ttt0\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/mtu\s+6000/) }
      it { expect(cfg_file).to match(/ovs_type\s+OVSIntPort/) }
      it { expect(cfg_file).to match(/ovs_bridge\s+br9/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(6) }  #  no more lines in the interface file
    end

    context "parse data from fixture" do
      let(:res) { subject.class.parse_file('bond_lacp', fixture_data('ifcfg-port'))[0] }

      it { expect(res[:method]).to eq :manual }
      it { expect(res[:mtu]).to eq '6000' }
      it { expect(res[:bridge]).to eq 'br9' }
      it { expect(res[:if_type].to_s).to eq 'ethernet' }
      it { expect(res[:if_provider].to_s).to eq 'ovs' }
    end

  end

end
