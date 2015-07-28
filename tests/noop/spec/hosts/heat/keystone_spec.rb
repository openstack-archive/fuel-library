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
  public_ssl           = Noop.hiera_structure('public_ssl/services')

  api_bind_port   = '8004'

  if public_ssl
    public_address  = Noop.hiera_structure('public_ssl/hostname')
    public_protocol = 'https'
  else
    public_address  = public_vip
    public_protocol = 'https'
  end
  public_url      = "#{public_protocol}://#{public_address}:#{api_bind_port}/v1/%(tenant_id)s"
  end

  test_ubuntu_and_centos manifest
end
