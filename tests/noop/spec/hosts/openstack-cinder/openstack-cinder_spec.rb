require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-cinder/openstack-cinder.pp'

describe manifest do
  shared_examples 'catalog' do

max_pool_size = 20
max_retries = '-1'
max_overflow = 20
queue_provider = Noop.hiera('queue_provider','rabbitmq')


if queue_provider
 it 'ensures cinder_config contains "oslo_messaging_rabbit/rabbit_ha_queues" ' do
  should contain_cinder_config('oslo_messaging_rabbit/rabbit_ha_queues')
 end
end

it 'should declare ::cinder class with correct database_max_* parameters' do
  should contain_class('cinder').with(
    'database_max_pool_size' => max_pool_size,
    'database_max_retries'   => max_retries,
    'database_max_overflow'  => max_overflow,
  )
end

  end # end of shared_examples

 test_ubuntu_and_centos manifest

end
