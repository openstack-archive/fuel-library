require 'spec_helper'

describe 'swift::keystone::auth' do

  let :params do
    { }
  end

  let :default_params do
    {
      :auth_name         => 'swift',
      :password          => 'swift_password',
      :port              => '8080',
      :tenant            => 'services',
      :email             => 'swift@localhost',
      :region            => 'RegionOne',
      :operator_roles    => ['admin', 'SwiftOperator'],
      :public_url        => 'http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s',
      :admin_url         => 'http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s',
      :internal_url      => 'http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s',
      :public_url_s3     => 'http://127.0.0.1:8080',
      :admin_url_s3      => 'http://127.0.0.1:8080',
      :internal_url_s3   => 'http://127.0.0.1:8080',
    }
  end

  shared_examples_for 'swift keystone auth' do
    context 'with default class parameters' do
      it_configures 'keystone auth configuration'

      ['admin', 'SwiftOperator'].each do |role_name|
        it { is_expected.to contain_keystone_role(role_name).with_ensure('present') }
      end
    end

    context 'with custom parameters' do
      before do
        params.merge!({
          :auth_name       => 'object_store',
          :password        => 'passw0rd',
          :tenant          => 'admin',
          :email           => 'object_store@localhost',
          :region          => 'RegionTwo',
          :operator_roles  => ['admin', 'SwiftOperator', 'Gopher'],
          :public_url      => 'https://10.0.0.10:8080/v1/AUTH_%(tenant_id)s',
          :internal_url    => 'https://10.0.0.11:8080/v1/AUTH_%(tenant_id)s',
          :admin_url       => 'https://10.0.0.11:8080/v1/AUTH_%(tenant_id)s',
          :public_url_s3   => 'https://10.0.0.10:8080',
          :internal_url_s3 => 'https://10.0.0.11:8080',
          :admin_url_s3    => 'https://10.0.0.11:8080',
        })
      end

      it_configures 'keystone auth configuration'

      ['admin', 'SwiftOperator', 'Gopher'].each do |role_name|
        it { is_expected.to contain_keystone_role(role_name).with_ensure('present') }
      end

      it { is_expected.to contain_keystone_endpoint("#{params[:region]}/#{params[:auth_name]}").with(
        :ensure       => 'present',
        :public_url   => params[:public_url],
        :admin_url    => params[:admin_url],
        :internal_url => params[:internal_url],
      )}

      it { is_expected.to contain_keystone_endpoint("#{params[:region]}/#{params[:auth_name]}_s3").with(
        :ensure       => 'present',
        :public_url   => params[:public_url_s3],
        :admin_url    => params[:admin_url_s3],
        :internal_url => params[:internal_url_s3],
      )}

      context 'when disabling endpoint configuration' do
        before do
          params.merge!(:configure_endpoint => false)
        end

        it { is_expected.to_not contain_keystone_endpoint('RegionOne/swift') }
      end

      context 'when disabling S3 endpoint' do
        before do
          params.merge!(:configure_s3_endpoint => false)
        end

        it { is_expected.to_not contain_keystone_service('swift_s3') }
        it { is_expected.to_not contain_keystone_endpoint('RegionOne/swift_s3') }
      end
    end

    context 'with deprecated endpoint parameters' do
      before do
        params.merge!({
          :auth_name         => 'object_store',
          :password          => 'passw0rd',
          :port              => '443',
          :tenant            => 'admin',
          :email             => 'object_store@localhost',
          :region            => 'RegionTwo',
          :operator_roles    => ['admin', 'SwiftOperator', 'Gopher'],
          :public_protocol   => 'https',
          :public_address    => 'public.example.org',
          :public_port       => '443',
          :admin_protocol    => 'https',
          :admin_address     => 'admin.example.org',
          :internal_protocol => 'https',
          :internal_address  => 'internal.example.org',
          :endpoint_prefix   => 'KEY_AUTH',
        })
      end

      let :p do
        default_params.merge( params )
      end

      it { is_expected.to contain_keystone_endpoint("#{p[:region]}/#{p[:auth_name]}").with(
        :ensure       => 'present',
        :public_url   => "#{p[:public_protocol]}://#{p[:public_address]}:#{p[:public_port]}/v1/#{p[:endpoint_prefix]}_%(tenant_id)s",
        :admin_url    => "#{p[:admin_protocol]}://#{p[:admin_address]}:#{p[:port]}",
        :internal_url => "#{p[:internal_protocol]}://#{p[:internal_address]}:#{p[:port]}/v1/#{p[:endpoint_prefix]}_%(tenant_id)s"
      )}

      it { is_expected.to contain_keystone_endpoint("#{p[:region]}/#{p[:auth_name]}_s3").with(
        :ensure       => 'present',
        :public_url   => "#{p[:public_protocol]}://#{p[:public_address]}:#{p[:port]}",
        :admin_url    => "#{p[:admin_protocol]}://#{p[:admin_address]}:#{p[:port]}",
        :internal_url => "#{p[:internal_protocol]}://#{p[:internal_address]}:#{p[:port]}"
      )}
    end
  end

  shared_examples_for 'keystone auth configuration' do
    let :p do
      default_params.merge( params )
    end

    it { is_expected.to contain_keystone_user(p[:auth_name]).with(
      :ensure   => 'present',
      :password => p[:password],
      :email    => p[:email]
    )}

    it { is_expected.to contain_keystone_user_role("#{p[:auth_name]}@#{p[:tenant]}").with(
      :ensure  => 'present',
      :roles   => ['admin'],
    )}

    it { is_expected.to contain_keystone_service(p[:auth_name]).with(
      :ensure      => 'present',
      :type        => 'object-store',
      :description => 'Openstack Object-Store Service'
    )}

    it { is_expected.to contain_keystone_service("#{p[:auth_name]}_s3").with(
    :ensure      => 'present',
    :type        => 's3',
    :description => 'Openstack S3 Service'
    )}
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'swift keystone auth'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'swift keystone auth'
  end




  context 'when overriding service name' do
    before do
      params.merge!({
        :service_name    => 'swift_service',
        :service_name_s3 => 'swift_service_s3',
      })
    end
    it 'configures correct user name' do
      is_expected.to contain_keystone_user('swift')
    end
    it 'configures correct user role' do
      is_expected.to contain_keystone_user_role('swift@services')
    end
    it 'configures correct service name' do
      is_expected.to contain_keystone_service('swift_service')
      is_expected.to contain_keystone_service('swift_service_s3')
    end
    it 'configures correct endpoint name' do
      is_expected.to contain_keystone_endpoint('RegionOne/swift_service')
      is_expected.to contain_keystone_endpoint('RegionOne/swift_service_s3')
    end
  end

end
