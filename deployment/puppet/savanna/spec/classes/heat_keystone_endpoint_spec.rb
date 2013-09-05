require 'spec_helper'

describe 'savanna::keystone::auth' do

  let :params do
    {
      :password           => 'savanna-passw0rd',
      :email              => 'savanna@localhost',
      :auth_name          => 'savanna',
      :configure_endpoint => true,
      :public_address     => '127.0.0.1',
      :admin_address      => '127.0.0.1',
      :internal_address   => '127.0.0.1',
      :service_type       => 'orchestration',
      :port               => '8004',
      :region             => 'RegionOne',
      :tenant             => 'services',
      :public_protocol    => 'http'
    }
  end

  shared_examples_for 'savanna keystone auth' do

    context 'without the required password parameter' do
      before { params.delete(:password) }
      it { expect { should raise_error(Puppet::Error) } }
    end

    it 'configures savanna user' do
      should contain_keystone_user( params[:auth_name] ).with(
        :ensure   => 'present',
        :password => params[:password],
        :email    => params[:email],
        :tenant   => params[:tenant]
      )
    end

    it 'configures savanna user roles' do
      should contain_keystone_user_role("#{params[:auth_name]}@#{params[:tenant]}").with(
        :ensure  => 'present',
        :roles   => ['admin']
      )
    end

    it 'configures savanna service' do
      should contain_keystone_service( params[:auth_name] ).with(
        :ensure      => 'present',
        :type        => params[:service_type],
        :description => 'savanna Service'
      )
    end

    it 'configure savanna endpoints' do
      should contain_keystone_endpoint("#{params[:region]}/#{params[:auth_name]}").with(
        :ensure       => 'present',
        :public_url   => "#{params[:public_protocol]}://#{params[:public_address]}:#{params[:port]}",
        :admin_url    => "http://#{params[:admin_address]}:#{params[:port]}",
        :internal_url => "http://#{params[:internal_address]}:#{params[:port]}"
      )
    end
  end


  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it 'configures savanna keystone auth'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it 'configures savanna keystone auth'
  end
end
