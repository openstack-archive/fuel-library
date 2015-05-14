require 'spec_helper'

describe Puppet::Type.type(:l3_route) do
  let(:subject) do
    Puppet::Type.type(:l3_route).new({
      :name => 'my_route',
      :destination => 'default',
      :gateway => '1.2.3.4',
    })
  end

  it 'should exist' do
    expect(subject).to be_a Puppet::Type.type(:l3_route)
  end

  %w(destination gateway metric).each do |property|
    it "should have '#{property}' property" do
      expect(subject.property property).not_to be_nil
    end
  end

  it 'destination should be 0.0.0.0 for a default route' do
    subject[:destination] = 'default'
    expect(subject[:destination]).to eq '0.0.0.0'
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

  context 'generates sibling resources' do
    let(:instances_data) do

    end

    
  end

end