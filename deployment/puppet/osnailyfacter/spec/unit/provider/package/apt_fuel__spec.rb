require 'spec_helper'

describe Puppet::Type.type(:package).provider(:apt_fuel) do

  it 'should exist' do
    expect(Puppet::Type.type(:package).provider(:apt_fuel).nil?).to eq false
  end

  it 'should use apt_fuel provider on Ubuntu' do
   if Facter.fact(:operatingsystem) == "Ubuntu"
      resource  = Puppet::Type.type(:package).new(
        :ensure    => :present,
        :name      => 'test'
      )
     expect(resource.provider).to be_kind_of(Puppet::Type.type(:package).provider(:apt_fuel))
   end
  end
end
