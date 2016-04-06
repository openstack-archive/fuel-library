require 'spec_helper'

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_ubuntu) do

  let(:input_data) do
    {
      :eth1 => {
                 :name     => "eth1",
                 :provider => "lnx_ubuntu",
                 :if_type  => "ethernet",
                 :ethtool  => { 'rings' => {'RX' => '2048', 'TX' => '2048'} },
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
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'lnx_ubuntu__spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "Ethtool options" do

    context 'format file' do
      subject { providers[:eth1] }
      let(:data) { subject.class.format_file('filepath', [subject]) }

      it { expect(data).to match %r(auto eth1) }
      it { expect(data).to match %r(iface eth1 inet manual) }
      it { expect(data).not_to match %r(.*ethernet.*) }
      it { expect(data).to match %r(post-up ethtool -G eth1 rx 2048.*) }
      it { expect(data).to match %r(post-up ethtool -G eth1 tx 2048.*) }
    end

    context "parse data from fixture" do
      let(:data) { subject.class.parse_file('eth1', fixture_data('ifcfg-eth1'))[0] }

      it { expect(data[:method]).to eq :static }
      it { expect(data[:ethtool]).to eq 'rings'=>{'RX' => '2048', 'TX' => '2048'} }

    end

  end
end
