require 'spec_helper'

describe 'heat::keystone::domain' do

  let :params do {
    :domain_name        => 'heat',
    :domain_admin       => 'heat_admin',
    :domain_admin_email => 'heat_admin@localhost',
    :domain_password    => 'domain_passwd'
    }
  end

  shared_examples_for 'heat keystone domain' do
    it 'configure heat.conf' do
      is_expected.to contain_heat_config('DEFAULT/stack_domain_admin').with_value(params[:domain_admin])
      is_expected.to contain_heat_config('DEFAULT/stack_domain_admin_password').with_value(params[:domain_password])
      is_expected.to contain_heat_config('DEFAULT/stack_domain_admin_password').with_secret(true)
      is_expected.to contain_heat_config('DEFAULT/stack_user_domain_name').with_value(params[:domain_name])
    end

    it 'should create keystone domain' do
      is_expected.to contain_keystone_domain('heat_domain').with(
        :ensure  => 'present',
        :enabled => 'true',
        :name    => params[:domain_name]
      )

      is_expected.to contain_keystone_user('heat_domain_admin').with(
        :ensure   => 'present',
        :enabled  => 'true',
        :name     => params[:domain_admin],
        :email    => params[:domain_admin_email],
        :password => params[:domain_password],
        :domain   => params[:domain_name],
      )
      is_expected.to contain_keystone_user_role('heat_admin@::heat').with(
        :roles => ['admin'],
      )
    end
  end


  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'heat keystone domain'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'heat keystone domain'
  end
end
