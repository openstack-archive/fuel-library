require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:l23_stored_config).provider(:sriov_centos7) do

  let(:facts) do
    {
      :osfamily => 'Redhat',
      :operatingsystem => 'CentOS',
      :l23_os => 'centos7',
    }
  end


  let(:input_data) do
    {
      :eth0 => {
                 :name     => "eth0",
                 :provider => 'sriov_centos7',
                 :sriov_numvfs => 63
               }
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
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'sriov_centos7_spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "parsing config files" do
    let(:res) { subject.class.parse_file('eth0', fixture_data('ifcfg-eth0'))[0] }
    it { expect(res[:method]).to eq 'manual' }
    it { expect(res[:onboot]).to eq true }
    it { expect(res[:if_type]).to eq :sriov }
    it { expect(res[:name]).to eq 'eth0' }
    it { expect(res[:sriov_numvfs]).to eq 63 }
    it { expect(res[:provider]).to eq :sriov_centos7 }
  end

  context "when formatting resources" do
    subject { providers[:eth0] }
    let(:res) { subject.class.format_file('filepath', [subject]) }
    it { expect(res).to match %r(DEVICE=eth0) }
    it { expect(res).to match %r(ONBOOT=yes) }
    it { expect(res).to match %r(BOOTPROTO=none) }
    it { expect(res).to match %r(^TYPE=sriov) }
    it { expect(res).to match %r(DEVICETYPE=sriov) }
    it { expect(res).to match %r(SRIOV_NUMFS=63) }
    it { expect(res).not_to match %r(IPADDR=.*) }
    it { expect(res).not_to match %r(GATEWAY=.*) }
    it { expect(res).not_to match %r(PREFIX=.*) }
    it { expect(res.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(6) }

    it 'should not remove GATEWAY from /etc/sysconfig/network' do
      subject.class.expects(:write_file).times(0)
      res
    end
    it 'should not write route to /etc/sysconfig/network-scripts/route-eth0' do
      subject.class.expects(:write_file).times(0)
      res
    end
  end

end