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
      :ovs2ovs_patch1 => {
        :name           => 'ovs2ovs-patch1',
        :ensure         => 'present',
        :if_type        => 'patch',
        :bridge         => ['ovs-br1'],
        :jacks          => ['ovs2ovs-patch2'],
        :onboot         => true,
        :method         => 'manual',
        :provider       => 'ovs_centos7',
      },
      :ovs2ovs_patch2 => {
        :name           => 'ovs2ovs-patch2',
        :ensure         => 'present',
        :if_type        => 'patch',
        :bridge         => ['ovs-br2'],
        :jacks          => ['ovs2ovs-patch1'],
        :onboot         => true,
        :method         => 'manual',
        :provider       => 'ovs_centos7',
      },
      :ovs2ovs_patch_with_tag => {
        :name           => 'ovs2ovs-tag',
        :ensure         => 'present',
        :if_type        => 'patch',
        :bridge         => ['ovs-brt2'],
        :jacks          => ['ovs2ovs-patcht1'],
        :vlan_id        => 3,
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
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'centos7_patches')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "ovs2ovs patch" do

    context 'format ovs2ovs-patch2 file' do
      subject { providers[:ovs2ovs_patch1] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(%r{DEVICE=ovs2ovs-patch1}) }
      it { expect(cfg_file).to match(%r{BOOTPROTO=none}) }
      it { expect(cfg_file).to match(%r{ONBOOT=yes}) }
      it { expect(cfg_file).to match(%r{TYPE=OVSPatchPort}) }
      it { expect(cfg_file).to match(%r{OVS_BRIDGE=ovs-br1}) }
      it { expect(cfg_file).to match(%r{OVS_PATCH_PEER=ovs2ovs-patch2}) }
      it { expect(cfg_file).to match(%r{DEVICETYPE=ovs}) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(7) }  #  no more lines in the interface file
    end

    context 'format ovs2ovs-patch2 file' do
      subject { providers[:ovs2ovs_patch2] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(%r{DEVICE=ovs2ovs-patch2}) }
      it { expect(cfg_file).to match(%r{BOOTPROTO=none}) }
      it { expect(cfg_file).to match(%r{ONBOOT=yes}) }
      it { expect(cfg_file).to match(%r{TYPE=OVSPatchPort}) }
      it { expect(cfg_file).to match(%r{OVS_BRIDGE=ovs-br2}) }
      it { expect(cfg_file).to match(%r{OVS_PATCH_PEER=ovs2ovs-patch1}) }
      it { expect(cfg_file).to match(%r{DEVICETYPE=ovs}) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(7) }  #  no more lines in the interface file
    end

    context 'format ovs2ovs-patch with tag file' do
      subject { providers[:ovs2ovs_patch_with_tag] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(%r{DEVICE=ovs2ovs-tag}) }
      it { expect(cfg_file).to match(%r{BOOTPROTO=none}) }
      it { expect(cfg_file).to match(%r{ONBOOT=yes}) }
      it { expect(cfg_file).to match(%r{TYPE=OVSPatchPort}) }
      it { expect(cfg_file).to match(%r{OVS_BRIDGE=ovs-brt2}) }
      it { expect(cfg_file).to match(%r{OVS_PATCH_PEER=ovs2ovs-patcht1}) }
      it { expect(cfg_file).to match(%r{OVS_OPTIONS="tag=3"}) }
      it { expect(cfg_file).to match(%r{DEVICETYPE=ovs}) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(8) }  #  no more lines in the interface file
    end

    context "parse ovs2ovs-patch1 data from fixture" do
      let(:res) { subject.class.parse_file('ovs2ovs-patch1', fixture_data('ifcfg-ovs2ovs-patch1'))[0] }
      it { expect(res[:name]).to eq 'ovs2ovs-patch1' }
      it { expect(res[:if_type].to_s).to eq 'patch' }
      it { expect(res[:bridge]).to match_array(['ovs-br1']) }
      it { expect(res[:jacks]).to match_array(['ovs2ovs-patch2']) }
      it { expect(res[:method].to_s).to eq 'manual' }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:provider].to_s).to eq 'ovs_centos7' }
    end

    context "parse ovs2ovs-patch2 data from fixture" do
      let(:res) { subject.class.parse_file('ovs2ovs-patch2', fixture_data('ifcfg-ovs2ovs-patch2'))[0] }
      it { expect(res[:name]).to eq 'ovs2ovs-patch2' }
      it { expect(res[:if_type].to_s).to eq 'patch' }
      it { expect(res[:bridge]).to match_array(['ovs-br2']) }
      it { expect(res[:jacks]).to match_array(['ovs2ovs-patch1']) }
      it { expect(res[:method].to_s).to eq 'manual' }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:provider].to_s).to eq 'ovs_centos7' }
    end

    context "parse ovs2ovs-tag data from fixture" do
      let(:res) { subject.class.parse_file('ovs2ovs-tag', fixture_data('ifcfg-ovs2ovs-tag'))[0] }
      it { expect(res[:name]).to eq 'ovs2ovs-tag' }
      it { expect(res[:if_type].to_s).to eq 'patch' }
      it { expect(res[:bridge]).to match_array(['ovs-brt2']) }
      it { expect(res[:jacks]).to match_array(['ovs2ovs-patcht1']) }
      it { expect(res[:vlan_id]).to eq('3') }
      it { expect(res[:method].to_s).to eq 'manual' }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:provider].to_s).to eq 'ovs_centos7' }
    end

  end

end
