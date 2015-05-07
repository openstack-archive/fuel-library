require 'spec_helper'

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_centos6) do

  let(:input_data) do
    {
      :eth1 => {
                 :name     => "eth1",
                 :method   => "static",
                 :ipaddr   => "169.254.0.1/24",
                 :provider => "lnx_centos6",
               },
      :eth2 => {
                 :name           => "eth2",
                 :onboot         => "yes",
                 :method         => "static",
                 :ipaddr         => "192.168.22.3/24",
                 :gateway        => "192.168.22.1",
                 :gateway_metric => "231",
                 :provider       => "lnx_centos6",
               },
      :'br-storage' => {
                 :name     => "br-storage",
                 :onboot   => "yes",
                 :method   => "static",
                 :ipaddr   => "192.168.55.33/24",
                 :provider => "lnx_centos6",
                 :routes   => { '10.109.22.0/24' => { 'gateway' => '192.168.55.54', 'destination' => '10.109.22.0/24' } }
               }
    }
  end

  let(:resources) do
    resources = {}
    input_data.each do |name, res|
      resources.store name, Puppet::Type.type(:l23_stored_config).new(res)
    end
    resources
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

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'lnx_centos6_spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "the method property" do
    context 'when dhcp' do
      let(:data) { subject.class.parse_file('eth0', fixture_data('ifcfg-eth0'))[0] }
      it { expect(data[:method]).to eq :dhcp }
    end
  end

  context "when formatting resources" do

    context 'with test interface eth1' do
      subject { providers[:eth1] }
      let(:data) { subject.class.format_file('filepath', [subject]) }
      it { expect(data).to match %r(DEVICE=eth1) }
      it { expect(data).to match %r(ONBOOT=yes) }
      it { expect(data).to match %r(BOOTPROTO=none) }
      it { expect(data).to match %r(IPADDR=169\.254\.0\.1) }
      it { expect(data).not_to match %r(GATEWAY=.*) }
      it { expect(data).not_to match %r(METRIC=.*) }
      it { expect(data).to match %r(PREFIX=24) }

      it 'should not remove GATEWAY from /etc/sysconfig/network' do
        subject.class.expects(:write_file).times(0)
        data
      end
      it 'should not write route to /etc/sysconfig/network-scripts/route-eth1' do
        subject.class.expects(:write_file).times(0)
        data
      end
    end

    context 'with test interface eth2 with default gateway' do
      subject { providers[:eth2] }
      let(:data) { subject.class.format_file('filepath', [subject]) }
      let(:content) { "NETWORKING=yes\nGATEWAY=5.5.5.5\n" }
      let(:file) { '/etc/sysconfig/network' }

      before(:each) do
        subject.class.stubs(:read_file).with(file).returns content
        subject.class.stubs(:write_file).returns true
      end

      it { expect(data).to match %r(DEVICE=eth2) }
      it { expect(data).to match %r(ONBOOT=yes) }
      it { expect(data).to match %r(BOOTPROTO=none) }
      it { expect(data).to match %r(IPADDR=192\.168\.22\.3) }
      it { expect(data).to match %r(GATEWAY=192\.168\.22\.1) }
      it { expect(data).to match %r(METRIC=231) }
      it { expect(data).to match %r(PREFIX=24) }

      it 'should remove GATEWAY from /etc/sysconfig/network' do
        subject.class.expects(:write_file).with(file, "NETWORKING=yes\n").returns true
        data
      end
      it 'should not write route to /etc/sysconfig/network-scripts/route-eth2' do
        subject.class.expects(:write_file).times(0)
        data
      end
    end

    context 'with test interface br-storage with routes' do
      subject { providers[:'br-storage'] }
      let(:data) { subject.class.format_file('filepath', [subject]) }
      let(:content) { "10.109.22.0/24 via 192.168.55.54 dev br-storage\n" }
      let(:file) { '/etc/sysconfig/network-scripts/route-br-storage' }

      before(:each) do
        subject.class.stubs(:write_file).returns true
      end

      it { expect(data).to match %r(DEVICE=br-storage) }
      it { expect(data).to match %r(ONBOOT=yes) }
      it { expect(data).to match %r(BOOTPROTO=none) }
      it { expect(data).to match %r(IPADDR=192\.168\.55\.33) }
      it { expect(data).to match %r(PREFIX=24) }
      it { expect(data).not_to match %r(ROUTES=.*) }

      it 'should write route to /etc/sysconfig/network-scripts/route-br-storage' do
        subject.class.expects(:write_file).with(file, content).returns true
        data
      end
    end

  end

end
