require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:l23_stored_config).provider(:lnx_ubuntu) do

  let(:input_data) do
    {
      :eth1 => {
        :name           => "eth1",
        :method         => "static",
        :ipaddr         => "169.254.1.3/24",
        :ipaddr_aliases => ["169.254.2.3/24", "169.254.3.3/24"],
        :routes         => {
            "10.1.0.0/16,metric:10" => {"gateway"=>"169.254.1.1", "destination"=>"10.1.0.0/16", "metric"=>"10"},
            "10.2.0.0/16" => {"gateway"=>"169.254.1.2", "destination"=>"10.2.0.0/16"},
            "10.3.0.0/16" => {"gateway"=>"169.254.3.1", "destination"=>"10.3.0.0/16"}
        },
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
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'l23_stored_config', 'lnx_ubuntu__addition_routes__spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
     File.read(fixture_file(file))
  end

  context "Multiple IP addresses per interface and addition routes" do

    context 'format file' do
      subject { providers[:eth1] }
      let(:cfg_file) { subject.class.format_file('filepath', [subject]) }
      it { expect(cfg_file).to match(/auto\s+eth1/) }
      it { expect(cfg_file).to match(/iface\s+eth1\s+inet\s+static/) }
      it { expect(cfg_file).to match(/address\s+169\.254\.1\.3\/24/) }
      it { expect(cfg_file).to match(/post-up\s+ip\s+addr\s+add\s+169\.254\.2\.3\/24\s+dev\s+eth1/) }
      it { expect(cfg_file).to match(/post-up\s+ip\s+addr\s+add\s+169\.254\.3\.3\/24\s+dev\s+eth1/) }
      it { expect(cfg_file).to match(/post-up\s+ip\s+route\s+add\s+10\.1\.0\.0\/16\s+via\s+169\.254\.1\.1\s+metric\s+10/) }
      it { expect(cfg_file).to match(/post-up\s+ip\s+route\s+add\s+10\.2\.0\.0\/16\s+via\s+169\.254\.1\.2/) }
      it { expect(cfg_file).to match(/post-up\s+ip\s+route\s+add\s+10\.3\.0\.0\/16\s+via\s+169\.254\.3\.1/) }
      it { expect(cfg_file.split(/\n/).reject{|x| x=~/(^\s*$)|(^#.*$)/}.length). to eq(8) }  #  no more lines in the interface file
    end

    context "parse data from fixture" do
      let(:data) { subject.class.parse_file('eth1', fixture_data('ifcfg-eth1'))[0] }
      it { expect(data[:method]).to eq :static }
      it { expect(data[:ipaddr]).to eq '169.254.1.3/24' }
      it { expect(data[:ipaddr_aliases]).to eq ['169.254.2.3/24', '169.254.3.3/24'] }
      it { expect(data[:routes]).to eq({
        "10.1.0.0/16,metric:10" => {"gateway"=>"169.254.1.1", "destination"=>"10.1.0.0/16", "metric"=>10},
        "10.2.0.0/16" => {"gateway"=>"169.254.1.2", "destination"=>"10.2.0.0/16"},
        "10.3.0.0/16" => {"gateway"=>"169.254.3.1", "destination"=>"10.3.0.0/16"}
      })}
    end
  end
end
