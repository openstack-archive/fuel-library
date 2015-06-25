require 'spec_helper'
require 'shared-examples'
manifest = 'dns/dns-client.pp'

describe manifest do
  shared_examples 'catalog' do

    management_vip = Noop.hiera 'management_vrouter_vip'

    it "should contain osnailyfacter::resolvconf" do
      should contain_class('osnailyfacter::resolvconf').with(
        'management_vip' => management_vip,
      )
    end

  end

  test_ubuntu_and_centos manifest
end

