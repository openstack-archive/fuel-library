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

    it { is_expected.to contain_keystone_tenant('services').with(
      :ensure      => 'present',
      :enabled     => true,
      :description => 'Tenant for the openstack services'
    )}
    it { is_expected.to contain_keystone_tenant('openstack').with(
      :ensure      => 'present',
      :enabled     => true,
      :description => 'admin tenant'
    )}
    it { is_expected.to contain_keystone_user('admin').with(
      :ensure                 => 'present',
      :enabled                => true,
      :tenant                 => 'openstack',
      :email                  => 'foo@bar',
      :password               => 'ChangeMe',
      :ignore_default_tenant  => 'false'
    )}
    it { is_expected.to contain_keystone_role('admin').with_ensure('present') }
    it { is_expected.to contain_keystone_user_role('admin@openstack').with(
      :roles  => ['admin'],
      :ensure => 'present'
    )}

  end

  describe 'when overriding optional params' do

    let :params do
      {
        :admin                  => 'admin',
        :email                  => 'foo@baz',
        :password               => 'foo',
        :admin_tenant           => 'admin',
        :admin_roles            => ['admin', 'heat_stack_owner'],
        :service_tenant         => 'foobar',
        :ignore_default_tenant  => 'true',
        :admin_tenant_desc      => 'admin something else',
        :service_tenant_desc    => 'foobar description',
      }
    end

    it { is_expected.to contain_keystone_tenant('foobar').with(
      :ensure  => 'present',
      :enabled => true,
      :description => 'foobar description'
    )}
    it { is_expected.to contain_keystone_tenant('admin').with(
      :ensure      => 'present',
      :enabled     => true,
      :description => 'admin something else'
    )}
    it { is_expected.to contain_keystone_user('admin').with(
      :ensure                 => 'present',
      :enabled                => true,
      :tenant                 => 'admin',
      :email                  => 'foo@baz',
      :password               => 'foo',
      :ignore_default_tenant  => 'true'
    )}
    it { is_expected.to contain_keystone_user_role('admin@admin').with(
      :roles  => ['admin', 'heat_stack_owner'],
      :ensure => 'present'
    )}

  end

  describe 'when disabling user configuration' do
    before do
      let :params do
        {
          :configure_user => false
        }
      end

      it { is_expected.to_not contain_keystone_user('keystone') }
      it { is_expected.to contain_keystone_user_role('keystone@openstack') }
    end
  end

  describe 'when disabling user and role configuration' do
    before do
      let :params do
        {
          :configure_user       => false,
          :configure_user_role  => false
        }
      end

      it { is_expected.to_not contain_keystone_user('keystone') }
      it { is_expected.to_not contain_keystone_user_role('keystone@openstack') }
    end
  end

end
