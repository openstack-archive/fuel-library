require 'spec_helper'
require 'yaml'

astute_filename = 'simple_neut_gre_ceph_sah_mur_cei.controller.yaml'
astute_file = File.expand_path(File.join(__FILE__, '..', '..', '..', 'astute.yaml', astute_filename))
settings = YAML.load_file(astute_file)
node = settings['fqdn']

describe node do
  # Facts
  let :facts do
    {
      :fqdn                 => node,
      :processorcount       => '4',
      :astute_settings_yaml => File.read(astute_file),
      :memorysize_mb        => '32138.66',
      :memorysize           => '31.39 GB',
      :kernel               => 'Linux',
      :l3_fqdn_hostname     => node,
      :l3_default_route     => '172.16.1.1',
    }
  end

  # Tests
  shared_examples 'controller' do

    it 'should declare keystone class with admin_token' do
      subject.should contain_class('keystone').with(
        'admin_token' => settings['keystone']['admin_token'],
      )
    end

    it 'should configure memcache_pool keystone cache backend' do
      should contain_keystone_config('token/caching').with(:value => 'false')
      should contain_keystone_config('cache/enabled').with(:value => 'true')
      should contain_keystone_config('cache/backend').with(:value => 'keystone.cache.memcache_pool')
      should contain_keystone_config('cache/memcache_servers').with(:value => settings['management_vip'] + ':11211')
      should contain_keystone_config('cache/memcache_dead_retry').with(:value => '300')
      should contain_keystone_config('cache/memcache_socket_timeout').with(:value => '3')
      should contain_keystone_config('cache/memcache_pool_maxsize').with(:value => '100')
      should contain_keystone_config('cache/memcache_pool_unused_timeout').with(:value => '60')
    end

  end

  # Ubuntu
  context 'on Ubuntu platforms' do
    before do
      facts.merge!( :osfamily => 'Debian' )
      facts.merge!( :operatingsystem => 'Ubuntu')
    end
    it_behaves_like 'controller'
  end

  # CentOS
  context 'on CentOS platforms' do
    before do
      facts.merge!( :osfamily => 'RedHat' )
      facts.merge!( :operatingsystem => 'CentOS')
    end
    it_behaves_like 'controller'
  end

end

