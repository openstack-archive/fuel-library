require 'spec_helper'

describe 'ceilometer::agent::auth' do

  let :pre_condition do
    "class { 'ceilometer': metering_secret => 's3cr3t' }"
  end

  let :params do
    { :auth_url         => 'http://localhost:5000/v2.0',
      :auth_region      => 'RegionOne',
      :auth_user        => 'ceilometer',
      :auth_password    => 'password',
      :auth_tenant_name => 'services',
      :enabled          => true,
    }
  end

  shared_examples_for 'ceilometer-agent-auth' do

    it 'configures authentication' do
      is_expected.to contain_ceilometer_config('service_credentials/os_auth_url').with_value('http://localhost:5000/v2.0')
      is_expected.to contain_ceilometer_config('service_credentials/os_region_name').with_value('RegionOne')
      is_expected.to contain_ceilometer_config('service_credentials/os_username').with_value('ceilometer')
      is_expected.to contain_ceilometer_config('service_credentials/os_password').with_value('password')
      is_expected.to contain_ceilometer_config('service_credentials/os_password').with_value(params[:auth_password]).with_secret(true)
      is_expected.to contain_ceilometer_config('service_credentials/os_tenant_name').with_value('services')
      is_expected.to contain_ceilometer_config('service_credentials/os_cacert').with(:ensure => 'absent')
    end

    context 'when overriding parameters' do
      before do
        params.merge!(:auth_cacert => '/tmp/dummy.pem')
      end
      it { is_expected.to contain_ceilometer_config('service_credentials/os_cacert').with_value(params[:auth_cacert]) }
    end

  end

end
