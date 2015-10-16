require 'spec_helper'

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_centos7) do

  let(:input_data) do
    {
      :eth0 => {
                 :name     => "eth0",
                 :method   => "dhcp",
                 :provider => "lnx_centos7",
                 :ethtool  => {"rings" => {"RX" => "2048", "TX" => "2048"}},
               },

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

  before(:each) do
    puppet_debug_override()
  end

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'lnx_centos7_spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "Ethtool options" do
    context 'format file' do
      subject { providers[:eth0] }
      let(:data) { subject.class.format_file('filepath', [subject]) }

      it { expect(data).to match %r(DEVICE=eth0) }
      it { expect(data).to match %r(ONBOOT=yes) }
      it { expect(data).to match %r(ETHTOOL_OPTS="-G eth0  rx 2048  tx 2048 ;") }

    end

    context 'parse data from fixture' do
      let(:data) { subject.class.parse_file('eth0', fixture_data('ifcfg-eth0'))[0] }

      it { expect(data[:method]).to eq 'dhcp' }
      it { expect(data[:ethtool]).to eq 'rings' => {'RX' => '2048', 'TX' => '2048'} }
    end

  end
end
