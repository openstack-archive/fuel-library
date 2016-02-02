require 'spec_helper'

resources_map =     {
      :'p2p4' => {
                 :name     => 'p2p4',
                 :provider => 'sriov_ubuntu',
                 :sriov_numvfs => 7
               },
}

describe Puppet::Type.type(:l23_stored_config).provider(:sriov_ubuntu) do

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
  end

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'ubuntu_ports')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "formatting config files" do

    context 'SRIOV port p2p4' do
      subject { providers[:'p2p4'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+p2p4/) }
      it { expect(cfg_file).to match(/iface\s+p2p4\s+inet\s+manual/) }
      it { expect(cfg_file).to match(/up\s+echo\s+0\s+>\s*\/sys\/class\/net\/p2p4\/device\/sriov_numvfs/) }
      it { expect(cfg_file).to match(/sriov_numvfs\s+7/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(5) }
    end

  end

  context "parsing config files" do
    let(:res) { subject.class.parse_file('p2p4', fixture_data('ifcfg-p2p4'))[0] }
    it { expect(res[:method]).to eq :manual }
    it { expect(res[:onboot]).to eq true }
    it { expect(res[:name]).to eq 'p2p4' }
    it { expect(res[:sriov_numvfs]).to eq 7 }
    it { expect(res[:provider]).to eq :sriov_ubuntu }
  end

end
