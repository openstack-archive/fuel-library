require 'spec_helper'

describe 'openstack::cinder' do

  let :default_params do
    {
      :sql_connection       => 'sqlite:///relative/path/to/file.db',
      :cinder_user_password => 'cindeRUserPAssw0rD',
      :glance_api_servers   => ['glance-001:9292', 'glance-002:9292'],
    }
  end

  shared_examples_for 'cinder configuration' do
    context 'with a default config' do
      let :params do
        default_params
      end

      it { is_expected.to contain_class('cinder') }
      it { is_expected.to contain_class('cinder::glance') }
      it { is_expected.to contain_class('cinder::logging') }
      it { is_expected.to contain_class('cinder::scheduler') }
    end

    context 'with custom config' do
      let :params do
        default_params.merge(
          :bind_host           => '156.151.59.35',
          :identity_uri        => 'http://192.168.0.1:5000',
          :notification_driver => 'messagingv2',
          :manage_volumes      => true,
        )
      end

      it { is_expected.to contain_class('cinder::volume') }

      it { is_expected.to contain_class('cinder::api').with(
        :bind_host                  => params[:bind_host],
        :identity_uri               => params[:identity_uri],
        :keymgr_encryption_auth_url => "#{params[:identity_uri]}/v3",
      ) }

      it { is_expected.to contain_class('cinder::ceilometer').with(
          :notification_driver => params[:notification_driver],
      ) }
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :physicalprocessorcount => 2,
        :memorysize_mb => 1024,
        :openstack_version => { 'nova' => 'present' },
        :os_service_default => '<SERVICE DEFAULT>',
      }
    end

    it_configures 'cinder configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :physicalprocessorcount => 2,
        :memorysize_mb => 1024,
        :openstack_version => { 'nova' => 'present' },
        :os_service_default => '<SERVICE DEFAULT>',
        :operatingsystemmajrelease => '7',
      }
    end

    it_configures 'cinder configuration'
  end

end
