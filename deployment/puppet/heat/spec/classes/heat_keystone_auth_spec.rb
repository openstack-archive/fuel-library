require 'spec_helper'

describe 'heat::keystone::auth' do

  let :params do
    {
      :password           => 'heat-passw0rd',
      :email              => 'heat@localhost',
      :auth_name          => 'heat',
      :configure_endpoint => true,
      :service_type       => 'orchestration',
      :public_address     => '127.0.0.1',
      :admin_address      => '127.0.0.1',
      :internal_address   => '127.0.0.1',
      :port               => '8004',
      :version            => 'v1',
      :region             => 'RegionOne',
      :tenant             => 'services',
      :public_protocol    => 'http',
      :admin_protocol     => 'http',
      :internal_protocol  => 'http',
    }
  end

  shared_examples_for 'heat keystone auth' do

    context 'without the required password parameter' do
      before { params.delete(:password) }
      it { expect { should raise_error(Puppet::Error) } }
    end

    it 'configures heat user' do
      should contain_keystone_user( params[:auth_name] ).with(
        :ensure   => 'present',
        :password => params[:password],
        :email    => params[:email],
        :tenant   => params[:tenant]
      )
    end

    it 'configures heat user roles' do
      should contain_keystone_user_role("#{params[:auth_name]}@#{params[:tenant]}").with(
        :ensure  => 'present',
        :roles   => ['admin']
      )
    end

    it 'configures heat stack_user role' do
      should contain_keystone_role("heat_stack_user").with(
        :ensure  => 'present'
      )
    end


    it 'configures heat service' do
      should contain_keystone_service( params[:auth_name] ).with(
        :ensure      => 'present',
        :type        => params[:service_type],
        :description => 'Openstack Orchestration Service'
      )
    end

    it 'configure heat endpoints' do
      should contain_keystone_endpoint("#{params[:region]}/#{params[:auth_name]}").with(
        :ensure       => 'present',
        :public_url   => "#{params[:public_protocol]}://#{params[:public_address]}:#{params[:port]}/#{params[:version]}/%(tenant_id)s",
        :admin_url    => "#{params[:admin_protocol]}://#{params[:admin_address]}:#{params[:port]}/#{params[:version]}/%(tenant_id)s",
        :internal_url => "#{params[:internal_protocol]}://#{params[:internal_address]}:#{params[:port]}/#{params[:version]}/%(tenant_id)s"
      )
    end
  end


  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'heat keystone auth'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'heat keystone auth'
  end
end
