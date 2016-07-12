# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'roles/controller.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:primary_controller) { Noop.hiera 'primary_controller' }

    it 'should configure nova_flavor to manage flavor on primary-controller only' do
      if primary_controller
        should contain_nova_flavor('m1.micro-flavor').with(
          :ram  => 64,
          :disk => 0,
          :vcpu => 1
        )
      else
        should_not contain_nova_flavor('m1.micro-flavor')
      end
    end

    it 'should install cirros image on primary-controler only' do
      if primary_controller
        should contain_package('cirros-testvm')
      else
        should_not contain_package('cirros-testvm')
      end
    end

    it 'should set vm.swappiness sysctl to 10' do
      should contain_sysctl('vm.swappiness').with(
        'val' => '10',
      )
    end
    it 'should make sure python-openstackclient package is installed' do
      should contain_package('python-openstackclient').with(
        'ensure' => 'installed',
      )
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

