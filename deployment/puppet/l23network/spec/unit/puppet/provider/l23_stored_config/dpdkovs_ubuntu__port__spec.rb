require 'spec_helper'

describe Puppet::Type.type(:l23_stored_config).provider(:dpdkovs_ubuntu) do
  let(:input_data) {
    {
      :'enp1s0f0' => {
                 :name     => 'enp1s0f0',
                 :if_type  => 'ethernet',
                 :bridge   => 'br-prv',
                 :provider => 'dpdkovs_ubuntu',
               },
    }
  }

  let(:dpdk_ports_mapping) {
    {
      'dpdk0'    => {
        :interface => 'enp1s0f0',
        :port_type => [],
        :type => "dpdk",
        :provider => "dpdkovs",
        :vendor_specific => {
          "dpdk_driver" => "igb_uio",
          "dpdk_port" => "dpdk0"
        }
      }
    }
  }

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
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'dpdkovs_ubuntu__spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "formating config files" do
    context 'DPDKOVS port enp1s0f0' do
      subject { providers[:enp1s0f0] }
      let(:cfg_file) do
        subject.class.stubs(:get_dpdk_ports_mapping).returns(dpdk_ports_mapping)
        subject.class.format_file('filepath', [subject])
      end
      it { expect(cfg_file).to match(/allow-br-prv\s+enp1s0f0/) }
      it { expect(cfg_file).to match(/iface\s+enp1s0f0\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/ovs_type\s+DPDKOVSPort/) }
      it { expect(cfg_file).to match(/ovs_bridge\s+br-prv/) }
      it { expect(cfg_file).to match(/dpdk_port\s+dpdk0/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(5) }
    end
  end

  context "parsing config files" do
    context 'OVS port enp1s0f0' do
      let(:res) { subject.class.parse_file('enp1s0f0', fixture_data('ifcfg-enp1s0f0'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:name]).to eq 'enp1s0f0' }
      it { expect(res[:bridge]).to eq "br-prv" }
      it { expect(res[:if_provider].to_s).to eq 'dpdkovs' }
      it { expect(res[:dpdk_port].to_s).to eq 'dpdk0' }
    end
  end
end