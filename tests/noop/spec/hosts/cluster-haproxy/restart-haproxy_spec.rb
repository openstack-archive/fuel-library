# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'cluster-haproxy/restart-haproxy.pp'

describe manifest do

  shared_examples 'catalog' do

    it "should restart haproxy service" do
      expect(subject).to contain_exec('haproxy-restart').with(
        'command' => '/usr/lib/ocf/resource.d/fuel/ns_haproxy reload',
      )
    end

  end
  test_ubuntu_and_centos manifest
end
