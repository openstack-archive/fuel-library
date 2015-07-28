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

  public_vip           = Noop.hiera('public_vip')
  admin_address        = Noop.hiera('management_vip')
  public_ssl           = Noop.hiera_structure('public_ssl/services')

  if public_ssl
    public_address  = Noop.hiera_structure('public_ssl/hostname')
    public_protocol = 'https'
  else
    public_address  = public_vip
    public_protocol = 'https'
  end

  public_url          = "#{public_protocol}://#{public_address}:8004/v1/%(tenant_id)s"
  admin_url           = "http://#{admin_address}:8004/v1/%(tenant_id)s"
  internal_url        = "http://#{admin_address}:8004/v1/%(tenant_id)s"
  public_url_cfn      = "#{public_protocol}://#{public_address}:8000/v1"
  admin_url_cfn       = "http://#{admin_address}:8000/v1"
  internal_url_cfn    = "http://#{admin_address}:8000/v1"


  it 'class heat::keystone::auth should contain correct *_url' do
    should contain_class('heat::keystone::auth').with('public_url' => public_url)
    should contain_class('heat::keystone::auth').with('admin_url' => admin_url)
    should contain_class('heat::keystone::auth').with('internal_url' => internal_url)
  end

  it 'class heat::keystone::auth_cfn should contain correct *_url' do
    should contain_class('heat::keystone::auth_cfn').with('public_url' => public_url_cfn)
    should contain_class('heat::keystone::auth_cfn').with('admin_url' => admin_url_cfn)
    should contain_class('heat::keystone::auth_cfn').with('internal_url' => internal_url_cfn)
  end



  end

  test_ubuntu_and_centos manifest
end
