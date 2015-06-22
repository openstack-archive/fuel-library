require 'spec_helper'
describe 'nova::compute::ironic' do

  it 'configures ironic in nova.conf' do
    is_expected.to contain_nova_config('ironic/admin_username').with_value('admin')
    is_expected.to contain_nova_config('ironic/admin_password').with_value('ironic')
    is_expected.to contain_nova_config('ironic/admin_url').with_value('http://127.0.0.1:35357/v2.0')
    is_expected.to contain_nova_config('ironic/admin_tenant_name').with_value('services')
    is_expected.to contain_nova_config('ironic/api_endpoint').with_value('http://127.0.0.1:6385/v1')
    is_expected.to contain_nova_config('DEFAULT/compute_driver').with_value('nova.virt.ironic.IronicDriver')
  end

end
