require 'spec_helper'
require 'shared-examples'
manifest = 'horizon/horizon.pp'

describe manifest do
  shared_examples 'catalog' do

    bind_address = Noop.node_hash['internal_address'] # TODO: smakar change AFTER https://bugs.launchpad.net/fuel/+bug/1486048
    nova_quota = Noop.hiera 'nova_quota'
    management_vip = Noop.hiera('management_vip')
    keystone_url = "http://#{management_vip}:5000/v2.0"
    cache_options = nil
    cache_options = {'SOCKET_TIMEOUT' => 1,'SERVER_RETRIES' => 1,'DEAD_RETRY' => 1}
    neutron_advanced_config =  Noop.hiera_structure 'neutron_advanced_configuration'

    # Horizon
    it 'should declare openstack::horizon class' do
      should contain_class('openstack::horizon').with(
        'nova_quota'   => nova_quota,
        'bind_address' => bind_address,
      )
    end

    it 'should declare openstack::horizon class with keystone_url' do
        should contain_class('openstack::horizon').with('keystone_url' => keystone_url)
    end

    it 'should declare horizon class with cache_backend,cache_options,log_handler' do
        should contain_class('horizon').with(
            'cache_backend' => 'horizon.backends.memcached.HorizonMemcached',
            'cache_options' => cache_options,
            'log_handler'   => 'file',
        )
    end

    if neutron_advanced_config && neutron_advanced_config.has_key?('neutron_dvr')
      dvr = neutron_advanced_config['neutron_dvr']
      it 'should configure horizon for neutron DVR' do
         should contain_class('openstack::horizon').with(
           'neutron_options' => {'enable_distributed_router' => dvr},
         )
      end
    end

    it {
      should contain_service('httpd').with(
           'hasrestart' => true,
           'restart'    => 'apachectl graceful || apachectl restart'
      )
    }

    it {
      should contain_class('openstack::horizon').that_comes_before(
        'Haproxy_backend_status[keystone-admin]'
      )
    }

    it {
      should contain_class('openstack::horizon').that_comes_before(
        'Haproxy_backend_status[keystone-public]'
      )
    }

  end
  test_ubuntu_and_centos manifest
end

