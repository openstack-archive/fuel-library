require 'spec_helper'

describe 'swift::proxy::cache' do

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :processorcount  => 1,
      :concat_basedir  => '/var/lib/puppet/concat',
    }
  end

  let :pre_condition do
    'class { "concat::setup": }
     concat { "/etc/swift/proxy-server.conf": }
     class { "memcached": max_memory => 1 }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/23_swift_cache"
  end

  it { should contain_file(fragment_file).with_content(/[filter:cache]/) }
  it { should contain_file(fragment_file).with_content(/use = egg:swift#memcache/) }

  describe 'with defaults' do

    it { should contain_file(fragment_file).with_content(/memcache_servers = 127\.0\.0\.1:11211/) }

  end

  describe 'with overridden memcache server' do

    let :params do
      {:memcache_servers => ['10.0.0.1:1']}
    end

    it { should contain_file(fragment_file).with_content(/memcache_servers = 10\.0\.0\.1:1/) }

  end

  describe 'with overridden memcache server array' do

    let :params do
      {:memcache_servers => ['10.0.0.1:1', '10.0.0.2:2']}
    end

    it { should contain_file(fragment_file).with_content(/memcache_servers = 10\.0\.0\.1:1,10\.0\.0\.2:2/) }

  end

end
