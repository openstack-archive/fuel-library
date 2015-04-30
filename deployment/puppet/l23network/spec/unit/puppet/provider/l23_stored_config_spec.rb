require 'spec_helper'

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_centos6) do

  subject { described_class }

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'lnx_centos6_spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  describe "the method property" do
    describe 'when dhcp' do
      let(:data) { described_class.parse_file('eth0', fixture_data('ifcfg-eth0'))[0] }
      it { data[:method].should == :dhcp }
    end
  end

  describe "when formatting resources" do
    let(:eth1_provider) do
      stub('eth1_provider',
        :name                  => "eth1",
        :onboot                => nil,
        :method                => "static",
        :ipaddr                => "169.254.0.1/24",
        :mtu                   => nil,
        :vlan_id               => nil,
        :if_type               => nil,
        :bridge                => nil,
        :gateway               => nil,
        :gateway_metric        => nil,
        :bond_master           => nil,
        :bond_mode             => nil,
        :bond_miimon           => nil,
        :bond_lacp_rate        => nil,
        :bond_xmit_hash_policy => nil,
        :ethtool               => nil,
        :routes                => nil,
      )
    end

    describe 'with test interface eth1' do
      let(:data) { described_class.format_file('filepath', [eth1_provider]) }
     it { data.should match /DEVICE=eth1/ }
      it { data.should match /BOOTPROTO=none/ }
      it { data.should match /IPADDR=169\.254\.0\.1/ }
      it { data.should match /PREFIX=24/ }
    end

  end

end
