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

# DISABLE_SPEC
# TODO: fix url_available mock

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
    default_gateways = Noop.puppet_function 'get_default_gateways'

    default_gateways.each do |gateway|
      it "should contain ping_host for gateway: #{gateway}" do
        is_expected.to contain_ping_host(gateway).with('ensure' => 'up')
      end
    end
  end

  test_ubuntu_and_centos manifest
end
