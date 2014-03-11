require 'spec_helper'

describe 'sahara::keystone::auth' do

  let :params do
    {
      :password           => 'sahara-passw0rd',
      :email              => 'sahara@localhost',
      :auth_name          => 'sahara',
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

  shared_examples_for 'sahara keystone auth' do

    context 'without the required password parameter' do
      before { params.delete(:password) }
      it { expect { should raise_error(Puppet::Error) } }
    end

    it 'configures sahara user' do
      should contain_keystone_user( params[:auth_name] ).with(
        :ensure   => 'present',
        :password => params[:password],
        :email    => params[:email],
        :tenant   => params[:tenant]
      )
    end

    it 'configures sahara user roles' do
      should contain_keystone_user_role("#{params[:auth_name]}@#{params[:tenant]}").with(
        :ensure  => 'present',
        :roles   => ['admin']
      )
    end

    it 'configures sahara service' do
      should contain_keystone_service( params[:auth_name] ).with(
        :ensure      => 'present',
        :type        => params[:service_type],
        :description => 'sahara Service'
      )
    end

    it 'configure sahara endpoints' do
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

    it 'configures sahara keystone auth'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it 'configures sahara keystone auth'
  end
end
