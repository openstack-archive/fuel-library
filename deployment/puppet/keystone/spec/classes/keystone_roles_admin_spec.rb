require 'spec_helper'
describe 'keystone::roles::admin' do

  describe 'with only the required params set' do

    let :params do
      {
        :email          => 'foo@bar',
        :password       => 'ChangeMe',
        :service_tenant => 'services'
      }
    end

    it { should contain_keystone_tenant('services').with(
      :ensure      => 'present',
      :enabled     => true,
      :description => 'Tenant for the openstack services'
    )}
    it { should contain_keystone_tenant('openstack').with(
      :ensure      => 'present',
      :enabled     => true,
      :description => 'admin tenant'
    )}
    it { should contain_keystone_user('admin').with(
      :ensure      => 'present',
      :enabled     => true,
      :tenant      => 'openstack',
      :email       => 'foo@bar',
      :password    => 'ChangeMe'
    )}
    it { should contain_keystone_role('admin').with_ensure('present') }
    it { should contain_keystone_user_role('admin@openstack').with(
      :roles  => 'admin',
      :ensure => 'present'
    )}

  end

  describe 'when overriding optional params' do

    let :params do
      {
        :admin          => 'admin',
        :email          => 'foo@baz',
        :password       => 'foo',
        :admin_tenant   => 'admin',
        :service_tenant => 'foobar'
      }
    end

    it { should contain_keystone_tenant('foobar').with(
      :ensure  => 'present',
      :enabled => true,
      :description => 'Tenant for the openstack services'
    )}
    it { should contain_keystone_tenant('admin').with(
      :ensure      => 'present',
      :enabled     => true,
      :description => 'admin tenant'
    )}
    it { should contain_keystone_user('admin').with(
      :ensure      => 'present',
      :enabled     => true,
      :tenant      => 'admin',
      :email       => 'foo@baz',
      :password    => 'foo'
    )}
    it { should contain_keystone_user_role('admin@admin').with(
      :roles  => 'admin',
      :ensure => 'present'
    )}

  end

end
