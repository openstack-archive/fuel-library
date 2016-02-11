require 'spec_helper'

describe 'openstack::ceilometer' do

  shared_examples_for 'ceilometer services config' do

    [true, false].each do |ha_mode|
      context "on controller node with HA mode set to '#{ha_mode}'" do
        let :params do
          {
            :on_controller => true,
            :ha_mode       => ha_mode,
          }
        end

        it 'contains class ceilometer::agent::polling' do
          is_expected.to contain_class('ceilometer::agent::polling').with(
            :enabled           => !ha_mode,
            :compute_namespace => false,
            :ipmi_namespace    => false
          )
        end

        if ha_mode
          it { is_expected.to contain_class('ceilometer_ha::agent::central') }
        end
      end
    end

    context "on conroller node" do
      let :params do
        {
          :on_controller         => true,
          :keystone_password     => 'cEilomEtEr_pAss',
          :keystone_user         => 'ceilometer',
          :keystone_tenant       => 'services',
          :keystone_region       => 'Region007',
          :api_workers           => facts[:processorcount],
          :host                  => '10.254.0.9',
          :port                  => '8777',
          :keystone_auth_uri     => 'http://127.0.0.1:5000/',
          :keystone_identity_uri => 'http://127.0.0.1:35357/'
        }
      end

      it { is_expected.to contain_class('ceilometer') }
      it { is_expected.to contain_class('ceilometer::logging') }
      it { is_expected.to contain_class('ceilometer::db') }
      it { is_expected.to contain_class('ceilometer::expirer') }
      it { is_expected.to contain_class('ceilometer::agent::notification') }
      it { is_expected.to contain_class('ceilometer::alarm::evaluator') }
      it { is_expected.to contain_class('ceilometer::collector') }
      it { is_expected.to contain_class('ceilometer::alarm::notifier') }
      it { is_expected.to contain_class('ceilometer::client') }

      it { is_expected.to contain_class('ceilometer::agent::auth').with(
        :auth_url         => "#{params[:keystone_protocol]}://#{params[:keystone_host]}:5000/v2.0",
        :auth_password    => params[:keystone_password],
        :auth_region      => params[:keystone_region],
        :auth_tenant_name => params[:keystone_tenant],
        :auth_user        => params[:keystone_user],
      ) }

      it { is_expected.to contain_class('ceilometer::api').with(
          :keystone_auth_uri     => params[:keystone_auth_uri],
          :keystone_identity_uri => params[:keystone_identity_uri],
          :keystone_user         => params[:keystone_user],
          :keystone_password     => params[:keystone_password],
          :keystone_tenant       => params[:keystone_tenant],
          :host                  => params[:host],
          :port                  => params[:port],
          :api_workers           => params[:api_workers],
      ) }
    end

    context "on compute node" do
      let :params do
        {
          :on_compute => true,
        }
      end

      it 'contains class ceilometer::agent::polling' do
        is_expected.to contain_class('ceilometer::agent::polling').with(
          :central_namespace => false,
          :ipmi_namespace    => false
        )
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Debian',
        :processorcount  => 2,
        :memorysize_mb   => 4096,
        :os_service_default => '<SERVICE DEFAULT>',
      }
    end

    it_configures 'ceilometer services config'
  end

  context 'on RedHat platforms' do
    let :facts do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :processorcount  => 2,
        :memorysize_mb   => 4096,
        :os_service_default => '<SERVICE DEFAULT>',
        :operatingsystemmajrelease => '7',
      }
    end

    it_configures 'ceilometer services config'
  end

end
