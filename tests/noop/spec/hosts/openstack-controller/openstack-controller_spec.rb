require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-controller/openstack-controller.pp'

describe manifest do
  shared_examples 'catalog' do

    use_neutron = Noop.hiera 'use_neutron'
    primary_controller = Noop.hiera 'primary_controller'
    if !use_neutron && primary_controller
      floating_ips_range = Noop.hiera 'floating_network_range'
      access_hash  = Noop.hiera_structure 'access'
    end
    service_endpoint = Noop.hiera 'service_endpoint'
    if service_endpoint
      keystone_host = service_endpoint
    else
      keystone_host = Noop.hiera 'management_vip'
    end

    # TODO All this stuff should be moved to shared examples controller* tests.

    # Nova config options
    it 'nova config should have use_stderr set to false' do
      should contain_nova_config('DEFAULT/use_stderr').with(
        'value' => 'false',
      )
    end

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

    keystone_ec2_url = "http://#{keystone_host}:5000/v2.0/ec2tokens"
    it 'should declare class nova::api with keystone_ec2_url' do
      should contain_class('nova::api').with(
        'keystone_ec2_url' => keystone_ec2_url,
      )
    end

    it 'should configure keystone_ec2_url for nova api service' do
      should contain_nova_config('DEFAULT/keystone_ec2_url').with(
        'value' => keystone_ec2_url,
      )
    end

    it 'should configure nova quota for injected file path length' do
      should contain_class('nova::quota').with('quota_injected_file_path_length' => '4096')
      should contain_nova_config('DEFAULT/quota_injected_file_path_length').with(
        'value' => '4096',
      )
    end

    let (:memcached_serverrs) { Noop.hiera 'memcached_servers' }

    it 'nova config should contain right memcached servers list' do
      should contain_nova_config('keystone_authtoken/memcached_servers').with_value(memcached_servers.join(','))
    end

    if floating_ips_range && access_hash
      floating_ips_range.each do |ips_range|
        it "should configure nova floating IP range for #{ips_range}" do
          should contain_nova_floating_range(ips_range).with(
            'ensure'      => 'present',
            'pool'        => 'nova',
            'username'    => access_hash['user'],
            'api_key'     => access_hash['password'],
            'auth_method' => 'password',
            'auth_url'    => "http://#{keystone_host}:5000/v2.0/",
            'api_retries' => '10',
          )
        end
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

