# ROLE: virt
# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: ironic
# ROLE: controller
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder-block-device
# ROLE: cinder
# ROLE: ceph-osd
require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/connectivity_tests.pp'

describe manifest do
  before(:each) do
    Noop.puppet_function_load :url_available
    MockFunction.new(:url_available) do |function|
      allow(function).to receive(:call).and_return(true)
    end
  end

  shared_examples 'catalog' do
    default_gateway  = Noop.puppet_function, 'get_default_gateways'
    it { should contain_ping_host(default_gateway.join()).with('ensure' => 'up') }
  end

  test_ubuntu_and_centos manifest
end
