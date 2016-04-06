# ROLE: primary-controller

require 'spec_helper'
require 'shared-examples'
manifest = 'ceilometer/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for ceilometer auth' do
      should contain_class('ceilometer::keystone::auth')
    end
    it 'should use either public_vip or management_vip' do

      internal_protocol = 'http'
      internal_address  = Noop.hiera('management_vip')
      admin_protocol    = 'http'
      admin_address     = internal_address

      if Noop.hiera_structure('use_ssl', false)
        public_protocol = 'https'
        public_address = Noop.hiera_structure('use_ssl/ceilometer_public_hostname')
        internal_protocol = 'https'
        internal_address = Noop.hiera_structure('use_ssl/ceilometer_internal_hostname')
        admin_protocol = 'https'
        admin_address = Noop.hiera_structure('use_ssl/ceilometer_admin_hostname')
      elsif Noop.hiera_structure('public_ssl/services')
        public_address  = Noop.hiera_structure('public_ssl/hostname')
        public_protocol = 'https'
      else
        public_address = Noop.hiera('public_vip')
        public_protocol = 'http'
      end

      password = Noop.hiera_structure 'ceilometer/user_password'
      auth_name = Noop.hiera_structure 'ceilometer/auth_name', 'ceilometer'
      configure_endpoint = Noop.hiera_structure 'ceilometer/configure_endpoint', true
      configure_user = Noop.hiera_structure 'ceilometer/configure_user', true
      configure_user_role = Noop.hiera_structure 'ceilometer/configure_user_role', true
      service_name = Noop.hiera_structure 'ceilometer/service_name', 'ceilometer'
      region = Noop.hiera_structure 'ceilometer/region', 'RegionOne'
      tenant = Noop.hiera_structure 'ceilometer/tenant', 'services'

      public_url = "#{public_protocol}://#{public_address}:8777"
      internal_url = "#{internal_protocol}://#{internal_address}:8777"
      admin_url = "#{admin_protocol}://#{admin_address}:8777"

      should contain_class('ceilometer::keystone::auth').with(
        'password'            => password,
        'auth_name'           => auth_name,
        'configure_endpoint'  => configure_endpoint,
        'configure_user'      => configure_user,
        'configure_user_role' => configure_user_role,
        'service_name'        => service_name,
        'public_url'          => public_url,
        'internal_url'        => internal_url,
        'admin_url'           => admin_url,
        'region'              => region,
        'tenant'              => tenant,
      )
    end
  end

  test_ubuntu_and_centos manifest
end
