require 'spec_helper'
require 'ostruct'

describe Puppet::Type.type(:l3_route).provider(:lnx) do
  let(:resource) do
    Puppet::Type.type(:l3_route).new({
                                         :name => 'default',
                                         :destination => 'default',
                                         :gateway => '10.1.1.1',
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
    provider.property_hash = instances.first
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
        {:destination => "0.0.0.0/0", :gateway => "10.1.1.1", :metric => "0", :interface => "eth0"},
        {:destination => "0.0.0.0/0", :gateway => "10.20.0.2", :metric => "10", :interface => "eth1"},
    ]
  end

  let(:instances) do
    [
        {:destination => "0.0.0.0/0", :gateway => "10.1.1.1", :metric => "0", :interface => "eth0", :ensure => :present, :name => "0.0.0.0/0"},
        {:destination => "0.0.0.0/0", :gateway => "10.20.0.2", :metric => "10", :interface => "eth1", :ensure => :present, :name => "0.0.0.0/0,metric:10"}
    ]
  end

  before(:each) do
    subject.class.stubs(:routing_table).returns routing_table
    subject.class.stubs(:routes).returns routes
  end

  let(:catalog_resources) do
    {
        'eth0' => OpenStruct.new({:catalog => nil, :destination => "0.0.0.0/0", :gateway => "10.1.1.1", :metric => "0", :interface => nil}),
        'eth2' => OpenStruct.new({:catalog => nil, :destination => "0.0.0.0/0", :gateway => "10.1.1.2", :metric => "20", :interface => nil}),
    }
  end

  context 'retrieve the current state' do
    it 'can parse the routing table' do
      subject.class.unstub(:routes)
      expect(subject.class.routes).to eq routes
    end

    it 'can generate a list of instances' do
      expect(subject.class.instances.map { |i| i.property_hash }).to eq instances
    end

    it 'can prefetch' do
      resources = catalog_resources
      subject.class.prefetch resources
      expect(resources['eth0'].provider).to be_a Puppet::Provider
      expect(resources['eth0'].provider.name).to eq 'eth0'
      expect(resources['eth0'].provider.gateway).to eq '10.1.1.1'
      expect(resources['eth2'].provider).to be_nil
    end

    it 'exists?' do
      subject.property_hash[:ensure] = :present
      expect(subject.exists?).to eq true
      subject.property_hash[:ensure] = :absent
      expect(subject.exists?).to eq false
    end

    it 'can access all parameters' do
      [:destination, :metric, :gateway, :interface, :vendor_specific].each do |parameter|
        expect(subject.send parameter).to eq instances.first[parameter]
      end
    end

    it 'can set all parameters' do
      [:destination, :metric, :gateway, :interface, :vendor_specific].each do |parameter|
        subject.send "#{parameter}=".to_sym, 'test'
        expect(subject.send parameter).to eq 'test'
      end
    end

  end

  context 'create a new route' do
    it 'creates a new route' do
      subject.property_hash = {}
      subject.expects(:route_add).once
      subject.expects(:route_delete).never
      subject.expects(:route_change).never
      subject.create
      subject.flush
      expect(subject.property_hash).to eq({
                                              :destination => "0.0.0.0/0",
                                              :gateway => "10.1.1.1",
                                              :metric => "0",
                                              :interface => nil,
                                              :vendor_specific => nil,
                                          })
    end
  end

  context 'update existing route' do
    it 'updates the current route' do
      resource[:gateway] = '10.1.1.2'
      subject.expects(:route_add).never
      subject.expects(:route_delete).never
      subject.expects(:route_change).once
      subject.gateway = resource[:gateway]
      subject.flush
      expect(subject.property_hash).to eq({
                                              :destination=>"0.0.0.0/0",
                                              :gateway=>"10.1.1.2",
                                              :metric=>"0",
                                              :interface=>"eth0",
                                              :ensure=>:present,
                                              :name=>"0.0.0.0/0",
                                          })
    end
  end

  context 'delete existing route' do
    it 'deletes the current route' do
      subject.expects(:route_add).never
      subject.expects(:route_delete).once
      subject.expects(:route_change).never
      subject.destroy
      subject.flush
      expect(subject.property_hash).to eq({})
    end
  end

end
