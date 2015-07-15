require 'spec_helper'

describe 'sahara::api' do

  let :params do
    { :enabled        => true,
      :manage_service => true,
      :api_workers    => '0' }
  end

  shared_examples_for 'sahara-api' do

    context 'config params' do

      it { is_expected.to contain_class('sahara') }
      it { is_expected.to contain_class('sahara::params') }
      it { is_expected.to contain_class('sahara::policy') }

      it { is_expected.to contain_sahara_config('DEFAULT/api_workers').with_value('0') }
      it { is_expected.to contain_sahara_config('DEFAULT/host').with_value('0.0.0.0') }
      it { is_expected.to contain_sahara_config('DEFAULT/port').with_value('8386') }

    end

    context 'passing params' do
      let :params do
      {
        :api_workers => '2',
        :host => 'localhost',
        :port => '8387',
      }
      end

      it { is_expected.to contain_sahara_config('DEFAULT/api_workers').with_value('2') }
      it { is_expected.to contain_sahara_config('DEFAULT/host').with_value('localhost') }
      it { is_expected.to contain_sahara_config('DEFAULT/port').with_value('8387') }
    end

    [{:enabled => true}, {:enabled => false}].each do |param_hash|
      context "when service should be #{param_hash[:enabled] ? 'enabled' : 'disabled'}" do
        before do
          params.merge!(param_hash)
        end

        it 'configures sahara-api service' do

          is_expected.to contain_service('sahara-api').with(
            :ensure     => (params[:manage_service] && params[:enabled]) ? 'running' : 'stopped',
            :name       => platform_params[:api_service_name],
            :enable     => params[:enabled],
            :hasstatus  => true,
            :hasrestart => true,
            :require    => 'Package[sahara-api]'
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

      it 'configures sahara-api service' do

        is_expected.to contain_service('sahara-api').with(
          :ensure     => nil,
          :name       => platform_params[:api_service_name],
          :enable     => false,
          :hasstatus  => true,
          :hasrestart => true,
          :require    => 'Package[sahara-api]'
        )
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :api_service_name => 'sahara-api' }
    end

    it_configures 'sahara-api'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :api_service_name => 'openstack-sahara-api' }
    end

    it_configures 'sahara-api'
  end

end
