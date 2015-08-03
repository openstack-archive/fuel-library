require 'spec_helper'

describe 'heat::keystone::domain' do

  let :params do {
    :auth_url          => 'http://127.0.0.1:35357/v2.0',
    :keystone_admin    => 'admin',
    :keystone_password => 'admin_passwd',
    :keystone_tenant   => 'admin',
    :domain_name       => 'heat',
    :domain_admin      => 'heat_admin',
    :domain_password   => 'domain_passwd'
    }
  end

  shared_examples_for 'heat keystone domain' do
    it 'configure heat.conf' do
      is_expected.to contain_heat_config('DEFAULT/stack_domain_admin').with_value(params[:domain_admin])
      is_expected.to contain_heat_config('DEFAULT/stack_domain_admin_password').with_value(params[:domain_password])
      is_expected.to contain_heat_config('DEFAULT/stack_domain_admin_password').with_secret(true)
      is_expected.to contain_heat_config('DEFAULT/stack_user_domain_name').with_value(params[:domain_name])
    end

    it 'should exec helper script' do
      is_expected.to contain_exec('heat_domain_create').with(
        :command     => 'heat-keystone-setup-domain',
        :path        => '/usr/bin',
        :require     => 'Package[heat-common]',
        :logoutput   => 'on_failure',
        :environment => [
            "OS_TENANT_NAME=#{params[:keystone_tenant]}",
            "OS_USERNAME=#{params[:keystone_admin]}",
            "OS_PASSWORD=#{params[:keystone_password]}",
            "OS_AUTH_URL=#{params[:auth_url]}",
            "HEAT_DOMAIN=#{params[:domain_name]}",
            "HEAT_DOMAIN_ADMIN=#{params[:domain_admin]}",
            "HEAT_DOMAIN_PASSWORD=#{params[:domain_password]}"
        ]
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
