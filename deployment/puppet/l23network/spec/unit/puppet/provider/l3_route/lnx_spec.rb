require 'spec_helper'
require 'ostruct'

describe Puppet::Type.type(:l3_route).provider(:lnx) do
  let(:resource) do
    Puppet::Type.type(:l3_route).new({
      :name => 'default',
      :destination => 'default',
      :gateway => '192.168.0.1',
      :provider => 'lnx',
    })
  end

  let(:provider) do
    provider = resource.provider
    if ENV['SPEC_PUPPET_DEBUG']
      class << provider
        def debug(msg)
          puts msg
        end
      end
    end
    provider
  end

  let(:subject) { provider }

  let(:routing_table) do
    <<-eos
eth1     00000000        0200140A        0003    0       0       10   00000000        0       0       0
eth1     0000140A        00000000        0001    0       0       0       00FFFFFF        0       0       0
eth0  00000000    0101010A  0003   0      0    0    00000000 0    0     0
eth0  0001010A    00000000  0001   0      0    0    00FFFFFF 0    0     0
    eos
  end

  let(:routes) do
    [
        {:destination=>"0.0.0.0/0", :gateway=>"10.1.1.1", :metric=>"0", :interface=>"eth0"},
        {:destination=>"0.0.0.0/0", :gateway=>"10.20.0.2", :metric=>"10", :interface=>"eth1"},
    ]
  end

  let(:instances) do
    [
    {:destination=>"0.0.0.0/0", :gateway=>"10.1.1.1", :metric=>"0", :interface=>"eth0", :ensure=>:present, :name=>"0.0.0.0/0"},
    {:destination=>"0.0.0.0/0", :gateway=>"10.20.0.2", :metric=>"10", :interface=>"eth1", :ensure=>:present, :name=>"0.0.0.0/0,metric:10"}
    ]
  end

  before(:each) do
    subject.class.stubs(:routing_table).returns routing_table
    subject.class.stubs(:routes).returns routes
  end

  let(:catalog_resources) do
    {
      'eth0' => OpenStruct.new({:catalog => nil, :destination=>"0.0.0.0/0", :gateway=>"10.1.1.1", :metric=>"0", :interface=>nil}),
      'eth2' => OpenStruct.new({:catalog => nil, :destination=>"0.0.0.0/0", :gateway=>"10.1.1.2", :metric=>"20", :interface=>nil}),
    }
  end

  context 'it can retrieve the current state' do
    it 'can parse the routing table' do
      subject.class.unstub(:routes)
      expect(subject.class.routes).to eq routes
    end

    it 'can generate a list of instances' do
      expect(subject.class.instances.map {|i| i.property_hash }).to eq instances
    end

    it 'can prefetch' do
      resources = catalog_resources
      subject.class.prefetch resources
      expect(resources['eth0'].provider).to be_a Puppet::Provider
      expect(resources['eth0'].provider.name).to eq 'eth0'
      expect(resources['eth0'].provider.gateway).to eq '10.1.1.1'
      expect(resources['eth2'].provider).to be_nil
    end
  end

end