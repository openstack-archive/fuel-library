require 'spec_helper'

describe 'ceilometer::keystone::auth' do

  let :default_params do
    {
      :email              => 'ceilometer@localhost',
      :auth_name          => 'ceilometer',
      :configure_endpoint => true,
      :service_type       => 'metering',
      :public_address     => '127.0.0.1',
      :admin_address      => '127.0.0.1',
      :internal_address   => '127.0.0.1',
      :port               => '8777',
      :region             => 'RegionOne',
      :tenant             => 'services',
      :public_protocol    => 'http',
      :admin_protocol     => 'http',
      :internal_protocol  => 'http'
    }
  end

  shared_examples_for 'ceilometer keystone auth' do

    context 'without the required password parameter' do
      it { expect { should raise_error(Puppet::Error) } }
    end

    let :params do
      { :password => 'ceil0met3r-passZord' }
    end

    context 'with the required parameters' do
      it 'configures ceilometer user' do
        should contain_keystone_user( default_params[:auth_name] ).with(
          :ensure   => 'present',
          :password => params[:password],
          :email    => default_params[:email],
          :tenant   => default_params[:tenant]
        )
      end

      it 'configures ceilometer user roles' do
        should contain_keystone_user_role("#{default_params[:auth_name]}@#{default_params[:tenant]}").with(
          :ensure  => 'present',
          :roles   => ['admin','ResellerAdmin']
        )
      end

      it 'configures ceilometer service' do
        should contain_keystone_service( default_params[:auth_name] ).with(
          :ensure      => 'present',
          :type        => default_params[:service_type],
          :description => 'Openstack Metering Service'
        )
      end

      it 'configure ceilometer endpoints' do
        should contain_keystone_endpoint("#{default_params[:region]}/#{default_params[:auth_name]}").with(
          :ensure       => 'present',
          :public_url   => "#{default_params[:public_protocol]}://#{default_params[:public_address]}:#{default_params[:port]}",
          :admin_url    => "#{default_params[:admin_protocol]}://#{default_params[:admin_address]}:#{default_params[:port]}",
          :internal_url => "#{default_params[:internal_protocol]}://#{default_params[:internal_address]}:#{default_params[:port]}"
        )
      end
    end

    context 'with overriden parameters' do
      before do
        params.merge!({
          :email             => 'mighty-ceilometer@remotehost',
          :auth_name         => 'mighty-ceilometer',
          :service_type      => 'cloud-measuring',
          :public_address    => '10.0.0.1',
          :admin_address     => '10.0.0.2',
          :internal_address  => '10.0.0.3',
          :port              => '65001',
          :region            => 'RegionFortyTwo',
          :tenant            => 'mighty-services',
          :public_protocol   => 'https',
          :admin_protocol    => 'ftp',
          :internal_protocol => 'gopher'
        })
      end

      it 'configures ceilometer user' do
        should contain_keystone_user( params[:auth_name] ).with(
          :ensure   => 'present',
          :password => params[:password],
          :email    => params[:email],
          :tenant   => params[:tenant]
        )
      end

      it 'configures ceilometer user roles' do
        should contain_keystone_user_role("#{params[:auth_name]}@#{params[:tenant]}").with(
          :ensure  => 'present',
          :roles   => ['admin','ResellerAdmin']
        )
      end

      it 'configures ceilometer service' do
        should contain_keystone_service( params[:auth_name] ).with(
          :ensure      => 'present',
          :type        => params[:service_type],
          :description => 'Openstack Metering Service'
        )
      end

      it 'configure ceilometer endpoints' do
        should contain_keystone_endpoint("#{params[:region]}/#{params[:auth_name]}").with(
          :ensure       => 'present',
          :public_url   => "#{params[:public_protocol]}://#{params[:public_address]}:#{params[:port]}",
          :admin_url    => "#{params[:admin_protocol]}://#{params[:admin_address]}:#{params[:port]}",
          :internal_url => "#{params[:internal_protocol]}://#{params[:internal_address]}:#{params[:port]}"
        )
      end

      context 'with overriden full uri' do
        before do
          params.merge!({
            :public_url => 'https://public.host:443/ceilometer_pub',
            :admin_url => 'https://admin.host/ceilometer_adm',
            :internal_url => 'http://internal.host:80/ceilometer_int',
          })
        end
        it 'configure ceilometer endpoints' do
          should contain_keystone_endpoint("#{params[:region]}/#{params[:auth_name]}").with(
            :ensure       => 'present',
            :public_url   => params[:public_url],
            :admin_url    => params[:admin_url],
            :internal_url => params[:internal_url]
          )
        end
      end

      context 'with configure_endpoint = false' do
        before do
          params.delete!(:configure_endpoint)
          it 'does not configure ceilometer endpoints' do
            should_not contain_keystone_endpoint("#{params[:region]}/#{params[:auth_name]}")
          end
        end
      end
    end


  end


  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'ceilometer keystone auth'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'ceilometer keystone auth'
  end
end
