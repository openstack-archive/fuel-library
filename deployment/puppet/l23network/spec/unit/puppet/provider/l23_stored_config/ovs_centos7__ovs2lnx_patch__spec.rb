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
      :ovs2lnx_patch => {
        :name           => 'ovs2lnx-patch',
        :ensure         => 'present',
        :if_type        => 'vport',
        :bridge         => ['ovs-br', 'lnx-br'],
        :onboot         => true,
        :method         => 'manual',
        :provider       => 'ovs_centos7',
      },
      :ovs2lnx_bad_patch => {
        :name           => 'ovs2lnx-bpatch',
        :ensure         => 'present',
        :if_type        => 'vport',
        :bridge         => ['ovs-br', 'lnx-br', 'br-fake'],
        :onboot         => true,
        :method         => 'manual',
        :provider       => 'ovs_centos7',
      },
      :ovs2lnx_bad_patch2 => {
        :name           => 'ovs2lnx-bpatch2',
        :ensure         => 'present',
        :if_type        => 'vport',
        :bridge         => ['ovs-br1', 'ovs-br2'],
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
    subject.class.stubs(:provider_of).with('ovs-br').returns('ovs_centos7')
    subject.class.stubs(:provider_of).with('lnx-br').returns('lnx_centos7')
    subject.class.stubs(:provider_of).with('ovs-br1').returns('ovs_centos7')
    subject.class.stubs(:provider_of).with('ovs-br2').returns('ovs_centos7')
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

  context "ovs2lnx patch" do

    context 'format patch file' do
      subject { providers[:ovs2lnx_patch] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(%r{DEVICE=ovs2lnx-patch}) }
      it { expect(cfg_file).to match(%r{BOOTPROTO=none}) }
      it { expect(cfg_file).to match(%r{ONBOOT=yes}) }
      it { expect(cfg_file).to match(%r{TYPE=OVSIntPort}) }
      it { expect(cfg_file).to match(%r{BRIDGE=lnx-br}) }
      it { expect(cfg_file).to match(%r{OVS_BRIDGE=ovs-br}) }
      it { expect(cfg_file).to match(%r{DEVICETYPE=ovs}) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(7) }  #  no more lines in the interface file

    end

    context 'three bridges patch error' do
      subject { providers[:ovs2lnx_bad_patch] }
      it { expect{ subject.class.format_file('filepath', [subject])
      }.to raise_error(Puppet::Error, %r{Patch\s+ovs2lnx-bpatch\s+has\s+more\s+than\s+2\s+bridges:\s+\["ovs-br",\s+"lnx-br",\s+"br-fake"].\s+Patch\s+can\s+connect\s+\*ONLY\*\s+2\s+bridges!}) }
    end

    context 'the same provider of bridges error' do
      subject { providers[:ovs2lnx_bad_patch2] }
      it { expect{ subject.class.format_file('filepath', [subject])
      }.to raise_error(Puppet::Error, %r{Patch\s+ovs2lnx-bpatch2\s+has\s+the\s+same\s+provider\s+bridges:\s+\["ovs-br1",\s+"ovs-br2"\]\s+!}) }
    end


    context "parse patch data from fixture" do
      let(:res) { subject.class.parse_file('ovs2lnx-patch', fixture_data('ifcfg-ovs2lnx-patch'))[0] }
      it { expect(res[:name]).to eq 'ovs2lnx-patch' }
      it { expect(res[:if_type].to_s).to eq 'vport' }
      it { expect(res[:bridge]).to match_array(['lnx-br', 'ovs-br']) }
      it { expect(res[:method].to_s).to eq 'manual' }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:provider].to_s).to eq 'ovs_centos7' }
    end

  end

end
