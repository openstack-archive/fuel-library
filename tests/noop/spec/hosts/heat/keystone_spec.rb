require 'spec_helper'
require 'shared-examples'
manifest = 'heat/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for heat auth' do
      contain_class('heat::keystone::auth').with(
        'trusts_delegated_roles' => [],
      )
    end

    internal_protocol = 'http'
    internal_address = Noop.hiera('management_vip')
    admin_protocol = 'http'
    admin_address  = internal_address

    if Noop.hiera_structure('use_ssl', false)
      public_protocol = 'https'
      public_address  = Noop.hiera_structure('use_ssl/heat_public_hostname')
      internal_protocol = 'https'
      internal_address = Noop.hiera_structure('use_ssl/heat_internal_hostname')
      admin_protocol = 'https'
      admin_address = Noop.hiera_structure('use_ssl/heat_admin_hostname')
    elsif Noop.hiera_structure('public_ssl/services')
      public_protocol = 'https'
      public_address  = Noop.hiera_structure('public_ssl/hostname')
    else
      public_address  = Noop.hiera('public_vip')
      public_protocol = 'http'
    end

    public_url          = "#{public_protocol}://#{public_address}:8004/v1/%(tenant_id)s"
    internal_url        = "#{internal_protocol}://#{internal_address}:8004/v1/%(tenant_id)s"
    admin_url           = "#{admin_protocol}://#{admin_address}:8004/v1/%(tenant_id)s"
    public_url_cfn      = "#{public_protocol}://#{public_address}:8000/v1"
    internal_url_cfn    = "#{internal_protocol}://#{internal_address}:8000/v1"
    admin_url_cfn       = "#{admin_protocol}://#{admin_address}:8000/v1"

    it 'class heat::keystone::auth should contain correct *_url' do
      should contain_class('heat::keystone::auth').with('public_url' => public_url)
      should contain_class('heat::keystone::auth').with('internal_url' => internal_url)
      should contain_class('heat::keystone::auth').with('admin_url' => admin_url)
    end

    it 'class heat::keystone::auth_cfn should contain correct *_url' do
      should contain_class('heat::keystone::auth_cfn').with('public_url' => public_url_cfn)
      should contain_class('heat::keystone::auth_cfn').with('internal_url' => internal_url_cfn)
      should contain_class('heat::keystone::auth_cfn').with('admin_url' => admin_url_cfn)
    end

  end

  test_ubuntu_and_centos manifest
end
