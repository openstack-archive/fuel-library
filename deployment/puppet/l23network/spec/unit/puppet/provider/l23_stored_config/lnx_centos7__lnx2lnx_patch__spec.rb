require 'spec_helper'

resources_map =     {
      :'br1' => {
        :name     => "br1",
        :onboot   => "yes",
        :method   => "static",
        :if_type  => "bridge",
        :ipaddr   => "192.168.88.2/24",
        :provider     => "lnx_centos7",
      },
      :'br2' => {
        :name     => "br2",
        :onboot   => "yes",
        :method   => "static",
        :if_type  => "bridge",
        :ipaddr   => "192.168.99.2/24",
        :provider     => "lnx_centos7",
      },
      :'p_33470efd-0' => {
        :name     => 'p_33470efd-0',
        :if_type  => 'patch',
        :bridge   => ["br1"],
        :jacks    => ['p_33470efd-0', 'p_33470efd-1'],
        :provider => "lnx_centos7",
      },
      :'p_33470efd-1' => {
        :name     => "p_33470efd-1",
        :if_type  => 'patch',
        :bridge   => ["br2"],
        :jacks    => ['p_33470efd-0', 'p_33470efd-1'],
        :provider => "lnx_centos7",
      },
      :'p_33470efd-1_mtu' => {
        :name     => "p_33470efd-1",
        :if_type  => 'patch',
        :mtu      => 1800,
        :bridge   => ["br2"],
        :jacks    => ['p_33470efd-0', 'p_33470efd-1'],
        :provider => "lnx_centos7",
      },
}

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_centos7) do

  let(:input_data) { resources_map}

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
    return providers
  end

  before(:each) do
    puppet_debug_override()
    subject.class.stubs(:script_directory).returns(fixture_path)
  end

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'lnx_centos7__lnx2lnx_patch__spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "when formating config files" do

    context 'for LNX bridge br1' do
      subject { providers[:'br1'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/BOOTPROTO=none/) }
      it { expect(cfg_file).to match(/IPADDR=192.168.88.2/) }
      it { expect(cfg_file).to match(/DEVICE=br1/) }
      it { expect(cfg_file).to match(/ONBOOT=yes/) }
      it { expect(cfg_file).to match(/TYPE=Bridge/) }
      it { expect(cfg_file).to match(/PREFIX=24/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(6) }
    end

    context 'for LNX bridge br2' do
      subject { providers[:'br2'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/BOOTPROTO=none/) }
      it { expect(cfg_file).to match(/IPADDR=192.168.99.2/) }
      it { expect(cfg_file).to match(/DEVICE=br2/) }
      it { expect(cfg_file).to match(/ONBOOT=yes/) }
      it { expect(cfg_file).to match(/TYPE=Bridge/) }
      it { expect(cfg_file).to match(/PREFIX=24/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(6) }
    end

    context 'for lnx2lnx patchcord p_33470efd-0' do
      subject { providers[:'p_33470efd-0'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it do
        file_handle = mock
        file_handle.stubs(:write).with("ip link add p_33470efd-0 mtu 1500 type veth peer name p_33470efd-1 mtu 1500\n"\
                                       "ip link set up dev p_33470efd-1").returns true
        File.stubs(:open).yields(file_handle).returns(true)
        expect(cfg_file).to match(/BOOTPROTO=none/)
        expect(cfg_file).to match(/DEVICE=p_33470efd-0/)
        expect(cfg_file).to match(/BRIDGE=br1/)
        expect(cfg_file).to match(/ONBOOT=yes/)
        expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(4)
      end
    end

    context 'for lnx2lnx patchcord p_33470efd-1' do
      subject { providers[:'p_33470efd-1'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it do
        file_handle = mock
        file_handle.stubs(:write).with("ip link add p_33470efd-0 mtu 1500 type veth peer name p_33470efd-1 mtu 1500\n"\
                                       "ip link set up dev p_33470efd-1").returns true
        File.stubs(:open).yields(file_handle).returns(true)
        expect(cfg_file).to match(/BOOTPROTO=none/)
        expect(cfg_file).to match(/DEVICE=p_33470efd-1/)
        expect(cfg_file).to match(/BRIDGE=br2/)
        expect(cfg_file).to match(/ONBOOT=yes/)
        expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(4)
      end
    end

    context 'for lnx2lnx patchcord p_33470efd-1 with mtu' do
      subject { providers[:'p_33470efd-1_mtu'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it do
        file_handle = mock
        file_handle.stubs(:write).with("ip link add p_33470efd-0 mtu 1800 type veth peer name p_33470efd-1 mtu 1800\n"\
                                       "ip link set up dev p_33470efd-1").returns true
        File.stubs(:open).yields(file_handle).returns(true)
        expect(cfg_file).to match(/BOOTPROTO=none/)
        expect(cfg_file).to match(/DEVICE=p_33470efd-1/)
        expect(cfg_file).to match(/BRIDGE=br2/)
        expect(cfg_file).to match(/MTU=1800/)
        expect(cfg_file).to match(/ONBOOT=yes/)
        expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(5)
      end
    end


    context 'file writing error for lnx2lnx patchcord p_33470efd-1' do
      subject { providers[:'p_33470efd-1'] }
      it do
        file_handle = mock
        file_handle.stubs(:write).raises(IOError)
        File.stubs(:open).yields(file_handle).returns(true)
        expect{ subject.class.format_file('filepath', [subject]) }.to raise_error(Puppet::Error, %r{.*file\s+.*-ifcfg-p_33470efd-1\s+can\s+not\s+be\s+written!})
      end
    end

  end

  context "when parsing config files" do

    context 'for LNX bridge br1' do
      let(:res) { subject.class.parse_file('ifcfg-br1', fixture_data('ifcfg-br1'))[0] }
      it { expect(res[:method]).to eq 'manual' }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'br1' }
      it { expect(res[:if_type].to_s).to eq 'bridge' }
      it { expect(res[:provider].to_s).to eq 'lnx_centos7' }
    end

    context 'for LNX bridge br2' do
      let(:res) { subject.class.parse_file('ifcfg-br2', fixture_data('ifcfg-br2'))[0] }
      it { expect(res[:method]).to eq 'manual' }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'br2' }
      it { expect(res[:if_type].to_s).to eq 'bridge' }
      it { expect(res[:provider].to_s).to eq 'lnx_centos7' }
    end

    context 'for lnx2lnx patchcord p_33470efd-0' do
      let(:res) { subject.class.parse_file('ifcfg-p_33470efd-0', fixture_data('ifcfg-p_33470efd-0'))[0] }
      it { expect(res[:name]).to eq 'p_33470efd-0' }
      it { expect(res[:if_type].to_s).to eq 'patch' }
      it { expect(res[:jacks]).to eq ['p_33470efd-0', 'p_33470efd-1'] }
      it { expect(res[:method]).to eq 'manual' }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:provider].to_s).to eq 'lnx_centos7' }
    end

    context 'for lnx2lnx patchcord p_33470efd-1' do
      let(:res) { subject.class.parse_file('ifcfg-p_33470efd-1', fixture_data('ifcfg-p_33470efd-1'))[0] }
      it { expect(res[:name]).to eq 'p_33470efd-1' }
      it { expect(res[:if_type].to_s).to eq 'patch' }
      it { expect(res[:jacks]).to eq ['p_33470efd-0', 'p_33470efd-1'] }
      it { expect(res[:method]).to eq 'manual' }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:provider].to_s).to eq 'lnx_centos7' }
    end

  end

end
