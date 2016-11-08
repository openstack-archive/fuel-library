require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:l23_stored_config).provider(:dpdkovs_ubuntu) do

  let(:input_data) do
    {
      :br0 => {
        :name           => 'br0',
        :ensure         => 'present',
        :if_type        => 'bridge',
        :onboot         => true,
        :method         => 'manual',
        :provider       => 'dpdkovs_ubuntu',
        :datapath_type  => 'netdev',
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
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'dpdkovs_ubuntu__spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "standalone DPDKOVS bridge" do

    context 'format file' do
      subject { providers[:br0] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+br0/) }
      it { expect(cfg_file).to match(/allow-ovs\s+br0/) }
      it { expect(cfg_file).to match(/iface\s+br0\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/ovs_type\s+OVSBridge/) }
      it { expect(cfg_file).to match(/ovs_extra\s+set\s+Bridge\s+br0\s+datapath_type=netdev/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(5) }  #  no more lines in the interface file
    end

    context "parse data from fixture" do
      let(:res) { subject.class.parse_file('br0', fixture_data('ifcfg-bridge'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:name]).to eq 'br0' }
      it { expect(res[:if_type].to_s).to eq 'bridge' }
      it { expect(res[:if_provider].to_s).to eq 'dpdkovs' }
      it { expect(res[:datapath_type].to_s).to eq 'netdev' }
    end

  end

end
