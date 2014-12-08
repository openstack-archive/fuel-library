require 'spec_helper'

describe 'openstack::keystone' do

  # Params
  let :params do
    {
      :db_host     => '172.16.0.1',
      :db_password => 'dbpass',
      :admin_token => 'admintoken',
      :admin_email => 'admin@admin.int',
      :admin_password => 'adminpassword',
      :glance_user_password => 'glanceuserpassword',
      :nova_user_password => 'novauserpassword',
      :cinder_user_password => 'cinderuserpassword',
      :ceilometer_user_password => 'ceilometeruserpassword',
      :neutron_user_password => 'neutronuserpassword',
      :public_address => '172.16.1.1',
    }
  end
  # Facts
  let :facts do
    {
      :processorcount => 4,
      :memorysize_mb  => 32138.66,
      :memorysize => '31.39 GB',
    }
  end

  # Tests
  shared_examples 'openstack-keystone' do

    context 'with default parameters' do
      it 'should declare keystone class' do
        subject.should contain_class('keystone').with(
          'admin_token' => 'admintoken',
        )
      end
    end

    context 'with overridden parameters' do
      before do
        params.merge!({
          :memcache_servers => ['172.16.0.1', '172.16.0.2', '172.16.0.3'],
          :memcache_server_port => '11211',
        })
      end

      it 'configures memcache_pool cache backend' do
        should contain_keystone_config('token/caching').with(:value => 'false')
        should contain_keystone_config('cache/enabled').with(:value => 'true')
        should contain_keystone_config('cache/backend').with(:value => 'keystone.cache.memcache_pool')
        should contain_keystone_config('cache/memcache_servers').with(:value => '172.16.0.1:11211,172.16.0.2:11211,172.16.0.3:11211')
        should contain_keystone_config('cache/memcache_dead_retry').with(:value => '300')
        should contain_keystone_config('cache/memcache_socket_timeout').with(:value => '3')
        should contain_keystone_config('cache/memcache_pool_maxsize').with(:value => '100')
        should contain_keystone_config('cache/memcache_pool_unused_timeout').with(:value => '60')
        #should contain_keystone_config('').with('value' => '')
      end

    end

  end

  # Debian
  context 'on Debian platforms' do
    before do
      facts.merge!( :osfamily => 'Debian' )
    end
    it_behaves_like 'openstack-keystone'
  end

  #RedHat
  context 'on RedHat platforms' do
    before do
      facts.merge!( :osfamily => 'RedHat' )
    end
    it_behaves_like 'openstack-keystone'
  end

end
