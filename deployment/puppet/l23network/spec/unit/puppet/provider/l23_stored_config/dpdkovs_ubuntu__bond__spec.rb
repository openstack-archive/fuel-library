require 'spec_helper'

describe Puppet::Type.type(:l23_stored_config).provider(:dpdkovs_ubuntu) do
  let(:input_data) {
    {
      :bond_lacp => {
                :name             => 'bond_lacp',
                :ensure           => 'present',
                :if_type          => 'bond',
                :bridge           => 'br-prv',
                :mtu              => '9000',
                :onboot           => true,
                :method           => 'manual',
                :bond_mode        => 'balance-tcp',
                :bond_slaves      => ['enp1s0f0', 'enp1s0f1'],
                :bond_miimon      => '50',
                :bond_use_carrier => '0',
                :bond_lacp_rate   => 'fast',
                :bond_lacp        => 'active',
                :bond_updelay     => '111',
                :bond_downdelay   => '222',
                :bond_ad_select   => '2',   # unused for OVS
                :provider         => 'dpdkovs_ubuntu',
               },
    }
  }

  let(:dpdk_ports_mapping) {
    {
      'enp1s0f0' => 'dpdk0',
      'enp1s0f1' => 'dpdk1'
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
    providers
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

  context "DPDKOVS bond with two interfaces" do

    context 'format file' do
      subject { providers[:bond_lacp] }
      let(:cfg_file) do
        subject.class.stubs(:get_dpdk_ports_mapping).returns(dpdk_ports_mapping)
        subject.class.format_file('filepath', [subject])
      end
      it { expect(cfg_file).not_to match(/auto\s+bond_lacp/) }
      it { expect(cfg_file).to match(/allow-br-prv\s+bond_lacp/) }
      it { expect(cfg_file).to match(/iface\s+bond_lacp\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/mtu\s+9000/) }
      it { expect(cfg_file).to match(/ovs_bonds\s+dpdk0\s+dpdk1/) }
      it { expect(cfg_file).to match(/ovs_type\s+DPDKOVSBond/) }
      it { expect(cfg_file).to match(/ovs_bridge\s+br-prv/) }
      it { expect(cfg_file).to match(/ovs_options.+bond_mode=balance-tcp/) }
      it { expect(cfg_file).to match(/ovs_options.+other_config:bond-detect-mode=miimon/) }
      it { expect(cfg_file).to match(/ovs_options.+other_config:lacp-time=fast/) }
      it { expect(cfg_file).to match(/ovs_options.+other_config:bond-miimon-interval=50/) }
      it { expect(cfg_file).to match(/ovs_options.+bond_updelay=111/) }
      it { expect(cfg_file).to match(/ovs_options.+bond_downdelay=222/) }
      it { expect(cfg_file).to match(/ovs_options.+lacp=active/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(7) }  #  no more lines in the interface file
    end

    context "parse data from fixture" do
      let(:res) do
        subject.class.stubs(:get_dpdk_ports_mapping).returns(dpdk_ports_mapping)
        subject.class.parse_file('bond_lacp', fixture_data('ifcfg-bond_lacp'))[0]
      end
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:mtu]).to eq '9000' }
      it { expect(res[:bridge]).to eq 'br-prv' }
      it { expect(res[:if_type].to_s).to eq 'bond' }
      it { expect(res[:if_provider].to_s).to eq 'dpdkovs' }
      it { expect(res[:bond_mode]).to eq 'balance-tcp' }
      it { expect(res[:bond_miimon]).to eq '50' }
      it { expect(res[:bond_lacp_rate]).to eq 'fast' }
      it { expect(res[:bond_lacp]).to eq 'active' }
      it { expect(res[:bond_updelay]).to eq '111' }
      it { expect(res[:bond_downdelay]).to eq '222' }
      it { expect(res[:bond_slaves]).to eq ['enp1s0f0', 'enp1s0f1'] }
    end
  end
end