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
      :ovs_bridge => {
        :name           => 'ovs-bridge',
        :ensure         => 'present',
        :if_type        => 'bridge',
        :mtu            => '9000',
        :onboot         => true,
        :method         => 'manual',
        :provider       => 'ovs_centos7',
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
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'centos7_bridges')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "OVS bridge" do

    context 'format file' do
      subject { providers[:ovs_bridge] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(%r{DEVICE=ovs-bridge}) }
      it { expect(cfg_file).to match(%r{BOOTPROTO=none}) }
      it { expect(cfg_file).to match(%r{ONBOOT=yes}) }
      it { expect(cfg_file).to match(%r{TYPE=OVSBridge}) }
      it { expect(cfg_file).to match(%r{MTU=9000}) }
      it { expect(cfg_file).to match(%r{DEVICETYPE=ovs}) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(6) }  #  no more lines in the interface file

    end

    context "parse bridge data from fixture" do
      let(:res) { subject.class.parse_file('ovs-bridge', fixture_data('ifcfg-ovs-bridge'))[0] }
      it { expect(res[:name]).to eq 'ovs-bridge' }
      it { expect(res[:if_type].to_s).to eq 'bridge' }
      it { expect(res[:method].to_s).to eq 'manual' }
      it { expect(res[:mtu]).to eq '9000' }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:provider]).to eq :ovs_centos7 }
    end

  end

end
