require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_ubuntu) do

  let(:input_data) do
    {
      :eth1 => {
                 :name           => "eth1",
                 :method         => "static",
                 :ipaddr         => "169.254.0.1/24",
                 :delay_while_up => "25",
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

  # context "the method property" do
  #   context 'when dhcp' do
  #     let(:data) { subject.class.parse_file('eth0', fixture_data('ifcfg-eth0'))[0] }
  #     it { expect(data[:method]).to eq :dhcp }
  #   end
  # end

  context "just eth interface" do

    context 'format file' do
      subject { providers[:eth1] }
      let(:data) { subject.class.format_file('filepath', [subject]) }
      it { expect(data).to match(/auto\s+eth1/) }
      it { expect(data).to match(/iface\s+eth1\s+inet\s+static/) }
      it { expect(data).to match(/address\s+169\.254\.0\.1\/24/) }
      it { expect(data).to match(/post-up\s+sleep\s+25/) }
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
