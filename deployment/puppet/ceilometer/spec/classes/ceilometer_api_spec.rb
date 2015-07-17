require 'spec_helper'

describe 'ceilometer::api' do

  let :pre_condition do
    "class { 'ceilometer': metering_secret => 's3cr3t' }"
  end

  let :params do
    { :enabled           => true,
      :manage_service    => true,
      :keystone_host     => '127.0.0.1',
      :keystone_port     => '35357',
      :keystone_protocol => 'http',
      :keystone_user     => 'ceilometer',
      :keystone_password => 'ceilometer-passw0rd',
      :keystone_tenant   => 'services',
      :host              => '0.0.0.0',
      :port              => '8777',
      :package_ensure    => 'latest',
    }
  end

  shared_examples_for 'ceilometer-api' do

    context 'without required parameter keystone_password' do
      before { params.delete(:keystone_password) }
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    it { is_expected.to contain_class('ceilometer::params') }
    it { is_expected.to contain_class('ceilometer::policy') }

    it 'installs ceilometer-api package' do
      is_expected.to contain_package('ceilometer-api').with(
        :ensure => 'latest',
        :name   => platform_params[:api_package_name],
        :tag    => 'openstack',
      )
    end

    it 'configures keystone authentication middleware' do
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_host').with_value( params[:keystone_host] )
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_port').with_value( params[:keystone_port] )
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_protocol').with_value( params[:keystone_protocol] )
      is_expected.to contain_ceilometer_config('keystone_authtoken/admin_tenant_name').with_value( params[:keystone_tenant] )
      is_expected.to contain_ceilometer_config('keystone_authtoken/admin_user').with_value( params[:keystone_user] )
      is_expected.to contain_ceilometer_config('keystone_authtoken/admin_password').with_value( params[:keystone_password] )
      is_expected.to contain_ceilometer_config('keystone_authtoken/admin_password').with_value( params[:keystone_password] ).with_secret(true)
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_admin_prefix').with_ensure('absent')
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_uri').with_value( params[:keystone_protocol] + "://" + params[:keystone_host] + ":5000/" )
      is_expected.to contain_ceilometer_config('api/host').with_value( params[:host] )
      is_expected.to contain_ceilometer_config('api/port').with_value( params[:port] )
    end

    context 'when specifying keystone_auth_admin_prefix' do
      describe 'with a correct value' do
        before { params['keystone_auth_admin_prefix'] = '/keystone/admin' }
        it { is_expected.to contain_ceilometer_config('keystone_authtoken/auth_admin_prefix').with_value('/keystone/admin') }
      end

      [
        '/keystone/',
        'keystone/',
        'keystone',
        '/keystone/admin/',
        'keystone/admin/',
        'keystone/admin'
      ].each do |auth_admin_prefix|
        describe "with an incorrect value #{auth_admin_prefix}" do
          before { params['keystone_auth_admin_prefix'] = auth_admin_prefix }

          it { expect { is_expected.to contain_ceilomete_config('keystone_authtoken/auth_admin_prefix') }.to \
            raise_error(Puppet::Error, /validate_re\(\): "#{auth_admin_prefix}" does not match/) }
        end
      end
    end

    [{:enabled => true}, {:enabled => false}].each do |param_hash|
      context "when service should be #{param_hash[:enabled] ? 'enabled' : 'disabled'}" do
        before do
          params.merge!(param_hash)
        end

        it 'configures ceilometer-api service' do
          is_expected.to contain_service('ceilometer-api').with(
            :ensure     => (params[:manage_service] && params[:enabled]) ? 'running' : 'stopped',
            :name       => platform_params[:api_service_name],
            :enable     => params[:enabled],
            :hasstatus  => true,
            :hasrestart => true,
            :require    => 'Class[Ceilometer::Db]',
            :subscribe  => 'Exec[ceilometer-dbsync]'
          )
        end
      end
    end

    context 'with disabled service managing' do
      before do
        params.merge!({
          :manage_service => false,
          :enabled        => false })
      end

      it 'configures ceilometer-api service' do
        is_expected.to contain_service('ceilometer-api').with(
          :ensure     => nil,
          :name       => platform_params[:api_service_name],
          :enable     => false,
          :hasstatus  => true,
          :hasrestart => true
        )
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :api_package_name => 'ceilometer-api',
        :api_service_name => 'ceilometer-api' }
    end

    it_configures 'ceilometer-api'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :api_package_name => 'openstack-ceilometer-api',
        :api_service_name => 'openstack-ceilometer-api' }
    end

    it_configures 'ceilometer-api'
  end

  describe 'with custom auth_uri' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    before do
      params.merge!({
        :keystone_auth_uri => 'https://foo.bar:1234/',
      })
    end
    it 'should configure custom auth_uri correctly' do
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_uri').with_value( 'https://foo.bar:1234/' )
    end
  end

  describe "with custom keystone identity_uri" do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    before do
      params.merge!({ 
        :keystone_identity_uri => 'https://foo.bar:1234/',
      })
    end
    it 'configures identity_uri' do
      is_expected.to contain_ceilometer_config('keystone_authtoken/identity_uri').with_value("https://foo.bar:1234/");
      # since only auth_uri is set the deprecated auth parameters should
      # still get set in case they are still in use
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_host').with_value('127.0.0.1');
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_port').with_value('35357');
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_protocol').with_value('http');
    end
  end

  describe "with custom keystone identity_uri and auth_uri" do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    before do
      params.merge!({ 
        :keystone_identity_uri => 'https://foo.bar:35357/',
        :keystone_auth_uri => 'https://foo.bar:5000/v2.0/',
      })
    end
    it 'configures identity_uri and auth_uri but deprecates old auth settings' do
      is_expected.to contain_ceilometer_config('keystone_authtoken/identity_uri').with_value("https://foo.bar:35357/");
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_uri').with_value("https://foo.bar:5000/v2.0/");
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_admin_prefix').with(:ensure => 'absent')
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_port').with(:ensure => 'absent')
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_protocol').with(:ensure => 'absent')
      is_expected.to contain_ceilometer_config('keystone_authtoken/auth_host').with(:ensure => 'absent')
    end
  end

end
