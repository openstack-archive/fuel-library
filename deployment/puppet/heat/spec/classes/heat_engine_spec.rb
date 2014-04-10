require 'spec_helper'

describe 'heat::engine' do

  let :default_params do
    { :enabled                       => true,
      :heat_stack_user_role          => 'heat_stack_user',
      :heat_metadata_server_url      => 'http://127.0.0.1:8000',
      :heat_waitcondition_server_url => 'http://127.0.0.1:8000/v1/waitcondition',
      :heat_watch_server_url         => 'http://128.0.0.1:8003',
    }
  end

  shared_examples_for 'heat-engine' do
    [
      {},
      { :auth_encryption_key           => '1234567890AZERTYUIOPMLKJHGFDSQ' },
      { :auth_encryption_key           => 'foodummybar',
        :enabled                       => false,
        :heat_stack_user_role          => 'heat_stack_user',
        :heat_metadata_server_url      => 'http://127.0.0.1:8000',
        :heat_waitcondition_server_url => 'http://127.0.0.1:8000/v1/waitcondition',
        :heat_watch_server_url         => 'http://128.0.0.1:8003',
      }
    ].each do |new_params|
      describe 'when #{param_set == {} ? "using default" : "specifying"} parameters'

      let :params do
        new_params
      end

      let :expected_params do
        default_params.merge(params)
      end

      it { should contain_package('heat-engine').with_name(os_params[:package_name]) }

      it { should contain_service('heat-engine').with(
        :ensure     => expected_params[:enabled] ? 'running' : 'stopped',
        :name       => os_params[:service_name],
        :enable     => expected_params[:enabled],
        :hasstatus  => 'true',
        :hasrestart => 'true',
        :require    => [ 'File[/etc/heat/heat.conf]',
                         'Package[heat-common]',
                         'Package[heat-engine]'],
        :subscribe  => 'Exec[heat-dbsync]'
      ) }

      it { should contain_heat_config('DEFAULT/auth_encryption_key').with_value( expected_params[:auth_encryption_key] ) }
      it { should contain_heat_config('DEFAULT/heat_stack_user_role').with_value( expected_params[:heat_stack_user_role] ) }
      it { should contain_heat_config('DEFAULT/heat_metadata_server_url').with_value( expected_params[:heat_metadata_server_url] ) }
      it { should contain_heat_config('DEFAULT/heat_waitcondition_server_url').with_value( expected_params[:heat_waitcondition_server_url] ) }
      it { should contain_heat_config('DEFAULT/heat_watch_server_url').with_value( expected_params[:heat_watch_server_url] ) }
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :os_params do
      { :package_name => 'heat-engine',
        :service_name => 'heat-engine'
      }
    end

    it_configures 'heat-engine'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :os_params do
      { :package_name => 'openstack-heat-engine',
        :service_name => 'openstack-heat-engine'
      }
    end

    it_configures 'heat-engine'
  end
end
