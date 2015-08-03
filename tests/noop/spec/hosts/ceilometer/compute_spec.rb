require 'spec_helper'
require 'shared-examples'
manifest = 'ceilometer/compute.pp'

describe manifest do
  shared_examples 'catalog' do
    enabled = Noop.hiera_structure 'ceilometer/enabled'
    if enabled
      it 'should configure OS ENDPOINT TYPE for ceilometer' do
        should contain_ceilometer_config('service_credentials/os_endpoint_type').with(:value => 'internalURL')
      end
    end
  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

