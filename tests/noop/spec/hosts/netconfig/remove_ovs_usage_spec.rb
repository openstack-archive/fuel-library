# ROLE: virt
# ROLE: primary-controller
# ROLE: controller
require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/remove_ovs_usage.pp'
describe manifest do
  before(:each) do
    Noop.puppet_function_load :remove_ovs_usage
    MockFunction.new(:remove_ovs_usage) do |function|
      allow(function).to receive(:call).and_return(true)
    end
  end

  shared_examples 'catalog' do
    let(:network_scheme) {
      {}
    }
    it { should contain_file('/etc/hiera/override/configuration/remove_ovs_usage.yaml') }
  end
  test_ubuntu_and_centos manifest
end
