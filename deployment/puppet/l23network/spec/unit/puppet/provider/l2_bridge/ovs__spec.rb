#! /usr/bin/env ruby

require 'spec_helper'

provider_class = Puppet::Type.type(:l2_bridge).provider(:ovs)

describe provider_class do
  subject { provider_class }

  let (:resource) { Puppet::Type.type(:l2_bridge).new(
      :ensure       => 'present',
      :use_ovs      => true,
      :external_ids => { 'bridge-id' => 'br-floating' },
      :provider     => nil,
      :name         => 'br-floating',
       )
  }
  let (:provider) { described_class.new(resource) }


end
