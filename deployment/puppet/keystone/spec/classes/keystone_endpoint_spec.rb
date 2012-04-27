require 'spec_helper'

describe 'keystone::endpoint' do

  it { should contain_keystone_service('keystone').with(
    :ensure      => 'present',
    :type        => 'identity',
    :description => 'OpenStack Identity Service'
  )}

  describe 'with default parameters' do
    it { should contain_keystone_endpoint('keystone').with(
      :ensure => 'present',
      :public_url   => 'http://127.0.0.1:5000/v2.0',
      :admin_url    => 'http://127.0.0.1:35357/v2.0',
      :internal_url => 'http://127.0.0.1:5000/v2.0'
    )}
  end

  describe 'with overridden parameters' do

    let :params do
      {
        :public_address   => '10.0.0.1',
        :admin_address    => '10.0.0.2',
        :internal_address => '10.0.0.3',
        :public_port      => '23456',
        :admin_port       => '12345'
      }
    end

    it { should contain_keystone_endpoint('keystone').with(
      :ensure => 'present',
      :public_url   => 'http://10.0.0.1:23456/v2.0',
      :admin_url    => 'http://10.0.0.2:12345/v2.0',
      :internal_url => 'http://10.0.0.3:23456/v2.0'
    )}

  end

end
