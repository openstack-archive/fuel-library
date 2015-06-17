require 'spec_helper'

describe 'heat::api_cfn' do

  let :params do
    { :enabled       => true,
      :manage_service => true,
      :bind_host      => '127.0.0.1',
      :bind_port      => '1234',
      :workers        => '0' }
  end

  shared_examples_for 'heat-api-cfn' do

    context 'config params' do

      it { should contain_class('heat') }
      it { should contain_class('heat::params') }
      it { should contain_class('heat::policy') }

      it { should contain_heat_config('heat_api_cfn/bind_host').with_value( params[:bind_host] ) }
      it { should contain_heat_config('heat_api_cfn/bind_port').with_value( params[:bind_port] ) }
      it { should contain_heat_config('heat_api_cfn/workers').with_value( params[:workers] ) }

    end

    context 'with SSL socket options set' do
      let :params do
        {
          :use_ssl   => true,
          :cert_file => '/path/to/cert',
          :key_file  => '/path/to/key'
        }
      end

      it { should contain_heat_config('heat_api_cfn/cert_file').with_value('/path/to/cert') }
      it { should contain_heat_config('heat_api_cfn/key_file').with_value('/path/to/key') }
    end

    context 'with SSL socket options set with wrong parameters' do
      let :params do
        {
          :use_ssl   => true,
          :key_file  => '/path/to/key'
        }
      end

      it_raises 'a Puppet::Error', /The cert_file parameter is required when use_ssl is set to true/
    end

    context 'with SSL socket options set to false' do
      let :params do
        {
          :use_ssl   => false,
          :cert_file => false,
          :key_file  => false
        }
      end

      it { should contain_heat_config('heat_api_cfn/cert_file').with_ensure('absent') }
      it { should contain_heat_config('heat_api_cfn/key_file').with_ensure('absent') }
    end

    [{:enabled => true}, {:enabled => false}].each do |param_hash|
      context "when service should be #{param_hash[:enabled] ? 'enabled' : 'disabled'}" do
        before do
          params.merge!(param_hash)
        end

        it 'configures heat-api-cfn service' do

          should contain_service('heat-api-cfn').with(
            :ensure     => (params[:manage_service] && params[:enabled]) ? 'running' : 'stopped',
            :name       => platform_params[:api_service_name],
            :enable     => params[:enabled],
            :hasstatus  => true,
            :hasrestart => true,
            :subscribe  => ['Exec[heat-dbsync]']
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

      it 'configures heat-api-cfn service' do

        should contain_service('heat-api-cfn').with(
          :ensure     => nil,
          :name       => platform_params[:api_service_name],
          :enable     => false,
          :hasstatus  => true,
          :hasrestart => true,
          :subscribe  => ['Exec[heat-dbsync]']
        )
      end
    end
  end


  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :api_service_name => 'heat-api-cfn' }
    end

    it_configures 'heat-api-cfn'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :api_service_name => 'openstack-heat-api-cfn' }
    end

    it_configures 'heat-api-cfn'
  end

end
