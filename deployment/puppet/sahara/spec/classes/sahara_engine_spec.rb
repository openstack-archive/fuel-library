require 'spec_helper'

describe 'sahara::engine' do

  let :params do
    { :enabled               => true,
      :manage_service        => true,
      :infrastructure_engine => 'direct' }
  end

  shared_examples_for 'sahara-engine' do

    context 'config params' do

      it { is_expected.to contain_class('sahara') }
      it { is_expected.to contain_class('sahara::params') }
      it { is_expected.to contain_class('sahara::policy') }

      it { is_expected.to contain_sahara_config('DEFAULT/infrastructure_engine').with_value('direct') }

    end

    context 'with heat engine' do

      let :params do
        { :enabled               => true,
          :manage_service        => true,
          :infrastructure_engine => 'heat' }
      end

      it { is_expected.to contain_class('sahara') }
      it { is_expected.to contain_class('sahara::params') }
      it { is_expected.to contain_class('sahara::policy') }

      it { is_expected.to contain_sahara_config('DEFAULT/infrastructure_engine').with_value('heat') }

    end

    [{:enabled => true}, {:enabled => false}].each do |param_hash|
      context "when service should be #{param_hash[:enabled] ? 'enabled' : 'disabled'}" do
        before do
          params.merge!(param_hash)
        end

        it 'configures sahara-engine service' do

          is_expected.to contain_service('sahara-engine').with(
            :ensure     => (params[:manage_service] && params[:enabled]) ? 'running' : 'stopped',
            :name       => platform_params[:engine_service_name],
            :enable     => params[:enabled],
            :hasstatus  => true,
            :hasrestart => true,
            :require    => 'Package[sahara-engine]'
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

      it 'configures sahara-engine service' do

        is_expected.to contain_service('sahara-engine').with(
          :ensure     => nil,
          :name       => platform_params[:engine_service_name],
          :enable     => false,
          :hasstatus  => true,
          :hasrestart => true,
          :require    => 'Package[sahara-engine]'
        )
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :engine_service_name => 'sahara-engine' }
    end

    it_configures 'sahara-engine'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :engine_service_name => 'openstack-sahara-engine' }
    end

    it_configures 'sahara-engine'
  end

end
