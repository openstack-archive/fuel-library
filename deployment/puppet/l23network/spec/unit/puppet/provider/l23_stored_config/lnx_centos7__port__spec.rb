require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_centos7) do

  let(:facts) do
    {
      :osfamily => 'Redhat',
      :operatingsystem => 'CentOS',
      :l23_os => 'centos7',
    }
  end

  let(:input_data) do
    {
      :lnx_port => {
        :name           => 'lnx-port',
        :ensure         => 'present',
        :if_type        => 'ethernet',
        :mtu            => '9000',
        :onboot         => true,
        :method         => 'manual',
        :provider       => 'lnx_centos7',
      },
      :lnx_port_without_type => {
        :name           => 'lnx-port2',
        :ensure         => 'present',
        :mtu            => '9000',
        :onboot         => true,
        :method         => 'manual',
        :provider       => 'lnx_centos7',
      },
      :lnx_port_ethtool => {
        :name           => 'lnx-port3',
        :ensure         => 'present',
        :onboot         => true,
        :method         => 'manual',
        :ethtool        =>  {
           'offload' => {
              'generic-receive-offload'      => false,
              'generic-segmentation-offload' => false }},
        :provider       => 'lnx_centos7',
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
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'centos7_ports')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "lnx port" do

    context 'format file for lnx-port' do
      subject { providers[:lnx_port] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(%r{DEVICE=lnx-port}) }
      it { expect(cfg_file).to match(%r{BOOTPROTO=none}) }
      it { expect(cfg_file).to match(%r{ONBOOT=yes}) }
      it { expect(cfg_file).to match(%r{TYPE=Ethernet}) }
      it { expect(cfg_file).to match(%r{MTU=9000}) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(5) }  #  no more lines in the interface file
    end

    context 'format file for lnx-port2 without type' do
      subject { providers[:lnx_port_without_type] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(%r{DEVICE=lnx-port2}) }
      it { expect(cfg_file).to match(%r{BOOTPROTO=none}) }
      it { expect(cfg_file).to match(%r{ONBOOT=yes}) }
      it { expect(cfg_file).to match(%r{MTU=9000}) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(4) }  #  no more lines in the interface file
    end

    context 'format file for lnx-port3 ethtool' do
      subject { providers[:lnx_port_ethtool] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(%r{DEVICE=lnx-port3}) }
      it { expect(cfg_file).to match(%r{BOOTPROTO=none}) }
      it { expect(cfg_file).to match(%r{ONBOOT=yes}) }
      it { expect(cfg_file).to match(%r{ETHTOOL_OPTS="-K\s+lnx-port3\s+gro\s+off\s+gso\s+off\s+;"}) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(4) }  #  no more lines in the interface file
    end

    context "parse port lnx-port data from fixture" do
      let(:res) { subject.class.parse_file('lnx-port', fixture_data('ifcfg-lnx-port'))[0] }
      it { expect(res[:name]).to eq 'lnx-port' }
      it { expect(res[:if_type].to_s).to eq 'ethernet' }
      it { expect(res[:method].to_s).to eq 'manual' }
      it { expect(res[:mtu]).to eq '9000' }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:provider]).to eq :lnx_centos7 }
    end

    context "parse port lnx-port2 data from fixture" do
      let(:res) { subject.class.parse_file('lnx-port2', fixture_data('ifcfg-lnx-port2'))[0] }
      it { expect(res[:name]).to eq 'lnx-port2' }
      it { expect(res[:method].to_s).to eq 'manual' }
      it { expect(res[:mtu]).to eq '9000' }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:provider]).to eq :lnx_centos7 }
    end

    context "parse port lnx-port3 data from fixture" do
      let(:res) { subject.class.parse_file('lnx-port3', fixture_data('ifcfg-lnx-port3'))[0] }
      it { expect(res[:name]).to eq 'lnx-port3' }
      it { expect(res[:method].to_s).to eq 'manual' }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:ethtool]).to eq 'offload' => { 'generic-receive-offload'=>false, 'generic-segmentation-offload'=>false } }
      it { expect(res[:provider]).to eq :lnx_centos7 }
    end


  end

end
