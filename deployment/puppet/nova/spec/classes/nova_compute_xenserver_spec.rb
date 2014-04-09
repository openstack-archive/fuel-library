require 'spec_helper'

describe 'nova::compute::xenserver' do

  let :params do
    { :xenapi_connection_url      => 'https://127.0.0.1',
      :xenapi_connection_username => 'root',
      :xenapi_connection_password => 'passw0rd' }
  end

  context 'with required parameters' do

    it 'configures xenapi in nova.conf' do
      should contain_nova_config('DEFAULT/compute_driver').with_value('xenapi.XenAPIDriver')
      should contain_nova_config('DEFAULT/connection_type').with_value('xenapi')
      should contain_nova_config('DEFAULT/xenapi_connection_url').with_value(params[:xenapi_connection_url])
      should contain_nova_config('DEFAULT/xenapi_connection_username').with_value(params[:xenapi_connection_username])
      should contain_nova_config('DEFAULT/xenapi_connection_password').with_value(params[:xenapi_connection_password])
      should contain_nova_config('DEFAULT/xenapi_inject_image').with_value(false)
    end

    it 'installs xenapi with pip' do
      should contain_package('xenapi').with(
        :ensure   => 'present',
        :provider => 'pip'
      )
    end
  end
end
