require 'spec_helper'

resources_map =     {
      :'p2p2' => {
                 :name     => 'p2p2',
                 :if_type  => 'ethernet',
                 :provider => 'lnx_ubuntu',
               },
      :'p2p3' => {
                 :name     => 'p2p3',
                :ethtool        =>  {
                  'offload' => {
                    'generic-receive-offload'      => false,
                    'generic-segmentation-offload' => false }},
                 :provider => 'lnx_ubuntu',
               },

}

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_ubuntu) do

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

  context "formating config files" do

    context 'OVS port p2p2 ' do
      subject { providers[:'p2p2'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+p2p2/) }
      it { expect(cfg_file).to match(/iface\s+p2p2\s+inet\s+manual/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(2) }
    end

    context 'Phys port p2p3 with ethtool' do
      subject { providers[:'p2p3'] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+p2p3/) }
      it { expect(cfg_file).to match(/iface\s+p2p3\s+inet\s+manual/) }
      it { expect(cfg_file).to match(%r{post-up\s+ethtool\s+-K\s+p2p3\s+gro\s+off\s+|\s+true\s+#\s+generic-receive-offload}) }
      it { expect(cfg_file).to match(%r{post-up\s+ethtool\s+-K\s+p2p3\s+gso\s+off\s+|\s+true\s+#\s+generic-segmentation-offload}) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/^\s*$/}.length). to eq(4) }
    end

  end

  context "parsing config files" do

    context 'OVS port p2p2' do
      let(:res) { subject.class.parse_file('p2p2', fixture_data('ifcfg-p2p2'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'p2p2' }
      it { expect(res[:if_provider].to_s).to eq 'lnx' }
    end

    context 'Phys port p2p3 with ethtool' do
      let(:res) { subject.class.parse_file('p2p3', fixture_data('ifcfg-p2p3'))[0] }
      it { expect(res[:method]).to eq :manual }
      it { expect(res[:onboot]).to eq true }
      it { expect(res[:name]).to eq 'p2p3' }
      it { expect(res[:ethtool]).to eq 'offload' => { 'generic-receive-offload'=>false, 'generic-segmentation-offload'=>false } }
      it { expect(res[:if_provider].to_s).to eq 'lnx' }
    end


  end

end
