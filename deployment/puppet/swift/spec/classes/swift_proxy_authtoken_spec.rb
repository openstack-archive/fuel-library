require 'spec_helper'

describe 'swift::proxy::authtoken' do

  let :facts do
    {
      :concat_basedir => '/var/lib/puppet/concat',
    }
  end

  let :pre_condition do
    '
      include concat::setup
      concat { "/etc/swift/proxy-server.conf": }
    '
  end

  let :params do
    {
      :admin_token => 'admin_token',
      :admin_user => 'admin_user',
      :admin_tenant_name => 'admin_tenant_name',
      :admin_password => 'admin_password',
      :delay_auth_decision => 42,
      :auth_host => '1.2.3.4',
      :auth_port => 4682,
      :auth_protocol => 'https'
    }
  end

  it { should contain_keystone__client__authtoken('/etc/swift/proxy-server.conf').with(
    params
  )}

end
