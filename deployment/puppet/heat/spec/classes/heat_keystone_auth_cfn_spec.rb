require 'spec_helper'

describe 'heat::keystone::auth_cfn' do

  let :params do
    {:password => 'heat-passw0rd'}
  end

  shared_examples_for 'heat keystone auth' do

    context 'without the required password parameter' do
      before { params.delete(:password) }
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    context 'when overriding parameters' do
      before do
        params.merge!({
          :email              => 'heat-cfn@localhost',
          :auth_name          => 'heat-cfn',
          :configure_endpoint => true,
          :configure_service  => true,
          :service_type       => 'cloudformation',
          :region             => 'RegionOne',
          :tenant             => 'services',
          :public_url         => 'http://10.0.0.10:8000/v1',
          :admin_url          => 'http://10.0.0.11:8000/v1',
          :internal_url       => 'http://10.0.0.12:8000/v1',
        })
      end

      it 'configures heat user' do
        is_expected.to contain_keystone_user( params[:auth_name] ).with(
          :ensure   => 'present',
          :password => params[:password],
          :email    => params[:email],
          :tenant   => params[:tenant]
        )
      end

      it 'configures heat user roles' do
        is_expected.to contain_keystone_user_role("#{params[:auth_name]}@#{params[:tenant]}").with(
          :ensure  => 'present',
          :roles   => ['admin']
        )
      end

      it 'configures heat service' do
        is_expected.to contain_keystone_service( params[:auth_name] ).with(
          :ensure      => 'present',
          :type        => params[:service_type],
          :description => 'Openstack Cloudformation Service'
        )
      end

      it 'configure heat endpoints' do
        is_expected.to contain_keystone_endpoint("#{params[:region]}/#{params[:auth_name]}").with(
          :ensure       => 'present',
          :public_url   => params[:public_url],
          :admin_url    => params[:admin_url],
          :internal_url => params[:internal_url]
        )
      end

      context 'with service disabled' do
        before do
          params.merge!({
            :configure_service => false
          })
        end
        it { is_expected.to_not contain_keystone_service("#{params[:region]}/#{params[:auth_name]}") }
      end
    end

    context 'with deprecated endpoint parameters' do
      before do
        params.merge!({
          :public_protocol   => 'https',
          :public_address    => '10.10.10.10',
          :port              => '81',
          :version           => 'v2',
          :internal_protocol => 'http',
          :internal_address  => '10.10.10.11',
          :admin_protocol    => 'http',
          :admin_address     => '10.10.10.12'
        })
      end

      it { is_expected.to contain_keystone_endpoint('RegionOne/heat-cfn').with(
        :ensure       => 'present',
          :public_url   => "#{params[:public_protocol]}://#{params[:public_address]}:#{params[:port]}/#{params[:version]}",
          :admin_url    => "#{params[:admin_protocol]}://#{params[:admin_address]}:#{params[:port]}/#{params[:version]}",
          :internal_url => "#{params[:internal_protocol]}://#{params[:internal_address]}:#{params[:port]}/#{params[:version]}"
      ) }
    end

    context 'when overriding service name' do
      before do
        params.merge!({
          :service_name => 'heat-cfn_service'
        })
      end
      it 'configures correct user name' do
        is_expected.to contain_keystone_user('heat-cfn')
      end
      it 'configures correct user role' do
        is_expected.to contain_keystone_user_role('heat-cfn@services')
      end
      it 'configures correct service name' do
        is_expected.to contain_keystone_service('heat-cfn_service')
      end
      it 'configures correct endpoint name' do
        is_expected.to contain_keystone_endpoint('RegionOne/heat-cfn_service')
      end
    end

    context 'when disabling user configuration' do
      before do
        params.merge!( :configure_user => false )
      end

      it { is_expected.to_not contain_keystone_user('heat_cfn') }
      it { is_expected.to contain_keystone_user_role('heat-cfn@services') }

      it { is_expected.to contain_keystone_service('heat-cfn').with(
        :ensure       => 'present',
        :type         => 'cloudformation',
        :description  => 'Openstack Cloudformation Service'
      )}
    end

    context 'when disabling user and role configuration' do
      before do
        params.merge!(
          :configure_user       => false,
          :configure_user_role  => false
        )
      end

      it { is_expected.to_not contain_keystone_user('heat_cfn') }
      it { is_expected.to_not contain_keystone_user_role('heat-cfn@services') }

      it { is_expected.to contain_keystone_service('heat-cfn').with(
        :ensure       => 'present',
        :type         => 'cloudformation',
        :description  => 'Openstack Cloudformation Service'
      )}
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
