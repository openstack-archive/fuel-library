require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-controller/openstack-controller.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.

    # Nova config options
    it 'nova config should have report_interval set to 60' do
      should contain_nova_config('DEFAULT/report_interval').with(
        'value' => '60',
      )
    end
    it 'nova config should have service_down_time set to 180' do
      should contain_nova_config('DEFAULT/service_down_time').with(
        'value' => '180',
      )
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

