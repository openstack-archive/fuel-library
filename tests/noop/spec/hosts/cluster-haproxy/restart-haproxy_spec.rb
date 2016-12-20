# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'cluster-haproxy/restart-haproxy.pp'

describe manifest do

  shared_examples 'catalog' do

    it "should declare haproxy service with correct other_networks" do
      expect(subject).to contain_service('haproxy').with(
        'ensure'     => 'running',
        'name'       => 'p_haproxy',
        'provider'   => 'pacemaker',
        'enable'     => 'true',
        'hasstatus'  => 'true',
        'hasrestart' => 'true',
      )
    end

  end
  test_ubuntu_and_centos manifest
end
