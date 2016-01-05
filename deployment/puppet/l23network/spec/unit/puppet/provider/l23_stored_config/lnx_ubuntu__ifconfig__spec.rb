require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_ubuntu) do

  let(:input_data) do
    {
      :eth1 => {
                 :name           => 'eth1',
                 :method         => 'static',
                 :ipaddr         => '169.254.0.1/24',
                 :delay_while_up => '25',
                 :provider       => 'lnx_ubuntu',
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

  context "just eth interface" do

    context 'format file' do
      subject { providers[:eth1] }
      let(:data) { subject.class.format_file('filepath', [subject]) }
      it { p data ; expect(data).to match(/auto\s+eth1/) }
      it { expect(data).to match(/iface\s+eth1\s+inet\s+static/) }
      it { expect(data).to match(/address\s+169\.254\.0\.1\/24/) }
      it { expect(data).to match(/post-up\s+sleep\s+25/) }
      it { expect(data.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(4) }  #  no more lines in the interface file
    end

    context "parse data from fixture" do
      let(:data) { subject.class.parse_file('eth1', fixture_data('ifcfg-eth1'))[0] }
      it { expect(data[:method]).to eq :static }
      it { expect(data[:ipaddr]).to eq '169.254.0.1/24' }
      it { expect(data[:delay_while_up]).to eq 25 }
      #it { puts data.to_yaml.gsub('!ruby/sym ','') }
    end
  end
end

describe Puppet::Type.type(:l23_stored_config).provider(:ovs_ubuntu) do

  let(:input_data) do
    {
      :eth1 => {
                 :name           => 'eth1',
                 :method         => 'static',
                 :ipaddr         => '169.254.0.1/24',
                 :provider       => 'ovs_ubuntu',
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

  context "just eth interface with OVS provider" do

    context 'format file with OVS provider' do
      subject { providers[:eth1] }
      let(:data) { subject.class.format_file('filepath', [subject]) }
      it { p data ; expect(data).to match(/auto\s+eth1/) }
      it { expect(data).to match(/iface\s+eth1\s+inet\s+static/) }
      it { expect(data).to match(/address\s+169\.254\.0\.1\/24/) }
      it { expect(data.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(3) }  #  no more lines in the interface file
    end
  end
end

### multiple IP per interface
describe Puppet::Type.type(:l23_stored_config).provider(:lnx_ubuntu) do

  let(:input_data) do
    {
      :eth1 => {
                 :name           => "eth11",
                 :method         => "static",
                 :ipaddr         => "169.254.0.1/24",
                 :ipaddr_aliases => ['192.168.1.1/24','192.168.2.2/25','192.168.3.3/26'],
                 :provider       => "lnx_ubuntu",
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

  context "Multiple IP addresses per interface" do

    context 'format file' do
      subject { providers[:eth1] }
      let(:data) { subject.class.format_file('filepath', [subject]) }
      it { expect(data).to match(/auto\s+eth11/) }
      it { expect(data).to match(/iface\s+eth11\s+inet\s+static/) }
      it { expect(data).to match(/address\s+169\.254\.0\.1\/24/) }
      it { expect(data).to match(/post-up\s+ip\s+addr\s+add\s+192.168.1.1\/24\s+dev\s+eth11/) }
      it { expect(data).to match(/post-up\s+ip\s+addr\s+add\s+192.168.2.2\/25\s+dev\s+eth11/) }
      it { expect(data).to match(/post-up\s+ip\s+addr\s+add\s+192.168.3.3\/26\s+dev\s+eth11/) }
      it { expect(data.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(6) }  #  no more lines in the interface file
    end

    context "parse data from fixture" do
      let(:data) { subject.class.parse_file('eth11', fixture_data('ifcfg-eth11'))[0] }
      it { expect(data[:method]).to eq :static }
      it { expect(data[:ipaddr]).to eq '169.254.0.1/24' }
      it { expect(data[:ipaddr_aliases]).to eq ['192.168.1.1/24','192.168.2.2/25','192.168.3.3/26'] }
    end
  end
end
