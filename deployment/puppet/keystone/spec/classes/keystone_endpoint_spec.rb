require 'spec_helper'

describe 'keystone::endpoint' do

  it { should contain_keystone_service('keystone').with(
    :ensure      => 'present',
    :type        => 'identity',
    :description => 'OpenStack Identity Service'
  )}

  describe 'with default parameters' do
    it { should contain_keystone_endpoint('RegionOne/keystone').with(
      :ensure       => 'present',
      :public_url   => 'http://127.0.0.1:5000/v2.0',
      :admin_url    => 'http://127.0.0.1:35357/v2.0',
      :internal_url => 'http://127.0.0.1:5000/v2.0'
    )}
  end

  describe 'with overridden parameters' do

    let :params do
      { :version      => 'v42.6',
        :public_url   => 'https://identity.some.tld/the/main/endpoint',
        :admin_url    => 'https://identity-int.some.tld/some/admin/endpoint',
        :internal_url => 'https://identity-int.some.tld/some/internal/endpoint' }
    end

    it { should contain_keystone_endpoint('RegionOne/keystone').with(
      :ensure       => 'present',
      :public_url   => 'https://identity.some.tld/the/main/endpoint/v42.6',
      :admin_url    => 'https://identity-int.some.tld/some/admin/endpoint/v42.6',
      :internal_url => 'https://identity-int.some.tld/some/internal/endpoint/v42.6'
    )}
  end

  describe 'without internal_url parameter' do

    let :params do
      { :public_url => 'https://identity.some.tld/the/main/endpoint' }
    end

    it 'internal_url should default to public_url' do
      should contain_keystone_endpoint('RegionOne/keystone').with(
        :ensure       => 'present',
        :public_url   => 'https://identity.some.tld/the/main/endpoint/v2.0',
        :internal_url => 'https://identity.some.tld/the/main/endpoint/v2.0'
      )
    end
  end

  describe 'with deprecated parameters' do

    let :params do
      { :public_address   => '10.0.0.1',
        :admin_address    => '10.0.0.2',
        :internal_address => '10.0.0.3',
        :public_port      => '23456',
        :admin_port       => '12345',
        :region           => 'RegionTwo',
        :version          => 'v3.0' }
    end

    it { should contain_keystone_endpoint('RegionTwo/keystone').with(
      :ensure       => 'present',
      :public_url   => 'http://10.0.0.1:23456/v3.0',
      :admin_url    => 'http://10.0.0.2:12345/v3.0',
      :internal_url => 'http://10.0.0.3:23456/v3.0'
    )}

    describe 'public_address overrides public_url' do
      let :params do
        { :public_address => '10.0.0.1',
          :public_port    => '12345',
          :public_url     => 'http://10.10.10.10:23456/v3.0' }
      end

      it { should contain_keystone_endpoint('RegionOne/keystone').with(
        :ensure     => 'present',
        :public_url => 'http://10.0.0.1:12345/v2.0'
      )}
    end
  end

  describe 'with overridden deprecated internal_port' do

    let :params do
      { :internal_port => '12345' }
    end

    it { should contain_keystone_endpoint('RegionOne/keystone').with(
      :ensure       => 'present',
      :public_url   => 'http://127.0.0.1:5000/v2.0',
      :admin_url    => 'http://127.0.0.1:35357/v2.0',
      :internal_url => 'http://127.0.0.1:12345/v2.0'
    )}
  end

end
