require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:l23_stored_config).provider(:ovs_centos7) do

  let(:facts) do
    {
      :osfamily => 'Redhat',
      :operatingsystem => 'CentOS',
      :l23_os => 'centos7',
    }
  end

  let(:input_data) do
    {
      :ovs_bondlacp1 => {
        :name             => 'ovs-bondlacp1',
        :ensure           => 'present',
        :if_type          => 'bond',
        :bridge           => 'br0',
        :mtu              => '9000',
        :onboot           => true,
        :method           => 'manual',
        :bond_mode        => 'balance-tcp',
        :bond_slaves      => ['eth2', 'eth3'],
        :bond_miimon      => '50',
        :bond_use_carrier => '0',
        :bond_lacp_rate   => 'fast',
        :bond_lacp        => 'active',
        :bond_updelay     => '111',
        :bond_downdelay   => '222',
        :bond_ad_select   => '2',   # unused for OVS
        :provider         => "ovs_centos7",
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
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'centos7_bonds')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "OVS bond with two interfaces" do

    context 'format file' do
      subject { providers[:ovs_bondlacp1] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(%r{DEVICE=ovs-bondlacp1}) }
      it { expect(cfg_file).to match(%r{BOOTPROTO=none}) }
      it { expect(cfg_file).to match(%r{ONBOOT=yes}) }
      it { expect(cfg_file).to match(%r{TYPE=OVSBond}) }
      it { expect(cfg_file).to match(%r{OVS_BRIDGE=br0}) }
      it { expect(cfg_file).to match(%r{MTU=9000}) }
      it { expect(cfg_file).to match(%r{OVS_OPTIONS="bond_mode=balance-tcp other_config:bond-miimon-interval=50 \
other_config:bond-detect-mode=miimon other_config:lacp-time=fast bond_updelay=111 bond_downdelay=222 lacp=active"}) }
      it { expect(cfg_file).to match(%r{BOND_IFACES="eth2 eth3"}) }
      it { expect(cfg_file).to match(%r{DEVICETYPE=ovs}) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(9) }  #  no more lines in the interface file

    end

    context "parse data from fixture" do
      let(:res) { subject.class.parse_file('ovs-bondlacp1', fixture_data('ifcfg-ovs-bondlacp1'))[0] }
      it { expect(res[:mtu]).to eq '9000' }
      it { expect(res[:bridge]).to eq ['br0'] }
      it { expect(res[:if_type].to_s).to eq 'bond' }
      it { expect(res[:bond_mode]).to eq 'balance-tcp' }
      it { expect(res[:bond_miimon]).to eq '50' }
      it { expect(res[:bond_use_carrier].to_s).to eq '0' }
      it { expect(res[:bond_lacp_rate]).to eq 'fast' }
      it { expect(res[:bond_lacp]).to eq 'active' }
      it { expect(res[:bond_updelay]).to eq '111' }
      it { expect(res[:bond_downdelay]).to eq '222' }
      it { expect(res[:bond_slaves]).to eq ['eth2', 'eth3'] }
    end

  end

end
