require 'spec_helper'
require 'shared-examples'
manifest = 'ceilometer/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for ceilometer auth' do
      contain_class('ceilometer::keystone::auth')
    end
    it 'should use either public_vip or management_vip' do
      public_vip     = Noop.hiera('public_vip')
      public_ssl     = Noop.hiera_structure('public_ssl/services')

      if public_ssl
        public_address  = Noop.hiera_structure('public_ssl/hostname')
        public_protocol = 'https'
      else
        public_address = public_vip
        public_protocol = 'http'
      end
      admin_address = Noop.hiera 'management_vip'

      password = Noop.hiera_structure 'ceilometer/user_password'
      auth_name = Noop.hiera_structure 'ceilometer/auth_name', 'ceilometer'
      configure_endpoint = Noop.hiera_structure 'ceilometer/configure_endpoint', true
      configure_user = Noop.hiera_structure 'ceilometer/configure_user', true
      configure_user_role = Noop.hiera_structure 'ceilometer/configure_user_role', true
      service_name = Noop.hiera_structure 'ceilometer/service_name', 'ceilometer'
      region = Noop.hiera_structure 'ceilometer/region', 'RegionOne'

      public_url = "#{public_protocol}://#{public_address}:8777"
      admin_url = "http://#{admin_address}:8777"

      contain_class('ceilometer::keystone::auth').with(
        'password'            => password,
        'auth_name'           => auth_name,
        'configure_endpoint'  => configure_endpoint,
        'configure_user'      => configure_user,
        'configure_user_role' => configure_user_role,
        'service_name'        => service_name,
        'public_url'          => public_url,
        'internal_url'        => admin_url,
        'admin_url'           => admin_url,
        'region'              => region
      )
    end
  end

  test_ubuntu_and_centos manifest
end
