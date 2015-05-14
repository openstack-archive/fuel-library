require 'spec_helper'

describe Puppet::Type.type(:l3_route) do
  let(:subject) do
    Puppet::Type.type(:l3_route).new({
      :name => 'my_route',
      :destination => 'default',
      :gateway => '1.2.3.4',
      :interface => 'eth0',
    })
  end

  it 'should exist' do
    expect(subject).to be_a Puppet::Type.type(:l3_route)
  end

  %w(destination gateway metric interface).each do |property|
    it "should have '#{property}' property" do
      expect(subject.property property).not_to be_nil
    end
  end

  it 'destination should be 0.0.0.0/0 for default route' do
    subject[:destination] = 'default'
    expect(subject[:destination]).to eq '0.0.0.0/0'
  end

  it 'destination should be 0.0.0.0/0 for 0.0.0.0 route' do
    subject[:destination] = '0.0.0.0'
    expect(subject[:destination]).to eq '0.0.0.0/0'
  end

  it 'destination should be 1.2.3.4/32 for 1.2.3.4 route' do
    subject[:destination] = '1.2.3.4'
    expect(subject[:destination]).to eq '1.2.3.4/32'
  end

  it 'should fail for wrong IP address in destination' do
    expect {
      subject[:destination] = 'route'
    }.to raise_error
  end

  it 'should fail for wrong IP address in gateway' do
    expect {
      subject[:gateway] = 'gateway'
    }.to raise_error
  end

  context 'can remove unmanaged routes with the same destination' do
    let(:instances_data) do
      [
          { :name => 'default_route', :destination => '0.0.0.0/0', :gateway => '1.2.3.4', :metric => '0' },
          { :name => 'another_default_route', :destination => '0.0.0.0/0', :gateway => '5.6.7.8', :metric => '10' },
          { :name => 'misc_route', :destination => '192.168.0.0/24', :gateway => '192.168.0.1', :metric => '0' },
          { :name => 'local_route', :destination => '192.168.0.0/24', :gateway => '192.168.0.1', :metric => '0' },
      ]
    end

    let(:instances) do
      instances_data.map { |data| Puppet::Type.type(:l3_route).new data }
    end

    before(:each) do
      subject.class.stubs(:instances).returns instances
      subject.stubs(:catalog_resources).returns [subject]
    end

    it 'can get discovered routes' do
      expect(subject.discovered_routes.length).to eq 4
    end

    it 'can get catalog routes' do
      expect(subject.catalog_routes.length).to eq 1
    end

    it 'can generate a list of routes to remove' do
      to_remove = subject.generate
      expect(to_remove.length).to eq 3
    end

    it 'will not remove any routes if "purge" is not enabled' do
      subject[:purge] = false
      expect(subject.generate.length).to eq 0
    end
    
  end

end
