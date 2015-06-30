require 'spec_helper'

describe 'ceilometer::keystone::auth' do

  let :default_params do
    {
      :email              => 'ceilometer@localhost',
      :auth_name          => 'ceilometer',
      :configure_endpoint => true,
      :service_type       => 'metering',
      :region             => 'RegionOne',
      :tenant             => 'services',
      :public_url         => 'http://127.0.0.1:8777',
      :admin_url          => 'http://127.0.0.1:8777',
      :internal_url       => 'http://127.0.0.1:8777',
    }
  end

  shared_examples_for 'ceilometer keystone auth' do

    context 'without the required password parameter' do
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    let :params do
      { :password => 'ceil0met3r-passZord' }
    end

    context 'with the required parameters' do
      it 'configures ceilometer user' do
        is_expected.to contain_keystone_user( default_params[:auth_name] ).with(
          :ensure   => 'present',
          :password => params[:password],
          :email    => default_params[:email],
          :tenant   => default_params[:tenant]
        )
      end

      it 'configures ceilometer user roles' do
        is_expected.to contain_keystone_user_role("#{default_params[:auth_name]}@#{default_params[:tenant]}").with(
          :ensure  => 'present',
          :roles   => ['admin','ResellerAdmin']
        )
      end

      it 'configures ceilometer service' do
        is_expected.to contain_keystone_service( default_params[:auth_name] ).with(
          :ensure      => 'present',
          :type        => default_params[:service_type],
          :description => 'Openstack Metering Service'
        )
      end

      it 'configure ceilometer endpoints' do
        is_expected.to contain_keystone_endpoint("#{default_params[:region]}/#{default_params[:auth_name]}").with(
          :ensure       => 'present',
          :public_url   => default_params[:public_url],
          :admin_url    => default_params[:admin_url],
          :internal_url => default_params[:internal_url]
        )
      end
    end

    context 'with overridden parameters' do
      before do
        params.merge!({
          :email         => 'mighty-ceilometer@remotehost',
          :auth_name     => 'mighty-ceilometer',
          :service_type  => 'cloud-measuring',
          :region        => 'RegionFortyTwo',
          :tenant        => 'mighty-services',
          :public_url    => 'https://public.host:443/ceilometer_pub',
          :admin_url     => 'https://admin.host/ceilometer_adm',
          :internal_url  => 'http://internal.host:80/ceilometer_int',
        })
      end

      it 'configures ceilometer user' do
        is_expected.to contain_keystone_user( params[:auth_name] ).with(
          :ensure   => 'present',
          :password => params[:password],
          :email    => params[:email],
          :tenant   => params[:tenant]
        )
      end

      it 'configures ceilometer user roles' do
        is_expected.to contain_keystone_user_role("#{params[:auth_name]}@#{params[:tenant]}").with(
          :ensure  => 'present',
          :roles   => ['admin','ResellerAdmin']
        )
      end

      it 'configures ceilometer service' do
        is_expected.to contain_keystone_service( params[:auth_name] ).with(
          :ensure      => 'present',
          :type        => params[:service_type],
          :description => 'Openstack Metering Service'
        )
      end

      it 'configure ceilometer endpoints' do
        is_expected.to contain_keystone_endpoint("#{params[:region]}/#{params[:auth_name]}").with(
          :ensure       => 'present',
          :public_url   => params[:public_url],
          :admin_url    => params[:admin_url],
          :internal_url => params[:internal_url]
        )
      end

      context 'with configure_endpoint = false' do
        before do
          params.delete!(:configure_endpoint)
          it 'does not configure ceilometer endpoints' do
            is_expected.to_not contain_keystone_endpoint("#{params[:region]}/#{params[:auth_name]}")
          end
        end
      end
    end

    context 'with deprecated parameters' do
      before do
        params.merge!({
          :auth_name         => 'mighty-ceilometer',
          :region            => 'RegionFortyTwo',
          :public_address    => '10.0.0.1',
          :admin_address     => '10.0.0.2',
          :internal_address  => '10.0.0.3',
          :port              => '65001',
          :public_protocol   => 'https',
          :admin_protocol    => 'ftp',
          :internal_protocol => 'gopher'
        })
      end

      it 'configure ceilometer endpoints' do
        is_expected.to contain_keystone_endpoint("#{params[:region]}/#{params[:auth_name]}").with(
          :ensure       => 'present',
          :public_url   => "#{params[:public_protocol]}://#{params[:public_address]}:#{params[:port]}",
          :admin_url    => "#{params[:admin_protocol]}://#{params[:admin_address]}:#{params[:port]}",
          :internal_url => "#{params[:internal_protocol]}://#{params[:internal_address]}:#{params[:port]}"
        )
      end
    end

    context 'when overriding service name' do
      before do
        params.merge!({
          :service_name => 'ceilometer_service'
        })
      end
      it 'configures correct user name' do
        is_expected.to contain_keystone_user('ceilometer')
      end
      it 'configures correct user role' do
        is_expected.to contain_keystone_user_role('ceilometer@services')
      end
      it 'configures correct service name' do
        is_expected.to contain_keystone_service('ceilometer_service')
      end
      it 'configures correct endpoint name' do
        is_expected.to contain_keystone_endpoint('RegionOne/ceilometer_service')
      end
    end

    context 'when disabling user configuration' do
      before do
        params.merge!( :configure_user => false )
      end

      it { is_expected.to_not contain_keystone_user('ceilometer') }
      it { is_expected.to contain_keystone_user_role('ceilometer@services') }

      it { is_expected.to contain_keystone_service('ceilometer').with(
        :ensure => 'present',
        :type        => 'metering',
        :description => 'Openstack Metering Service'
      )}
    end

    context 'when disabling user and role configuration' do
      before do
        params.merge!(
          :configure_user       => false,
          :configure_user_role  => false
        )
      end

      it { is_expected.to_not contain_keystone_user('ceilometer') }
      it { is_expected.to_not contain_keystone_user_role('ceilometer@services') }

      it { is_expected.to contain_keystone_service('ceilometer').with(
        :ensure => 'present',
        :type        => 'metering',
        :description => 'Openstack Metering Service'
      )}
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
