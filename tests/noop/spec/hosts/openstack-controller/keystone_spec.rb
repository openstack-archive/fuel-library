require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-controller/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for nova auth' do
      contain_class('nova::keystone::auth')
    end

  public_vip           = Noop.hiera('public_vip')
  admin_address        = Noop.hiera('management_vip')
  public_ssl           = Noop.hiera_structure('public_ssl/services')

    if public_ssl
      public_address  = Noop.hiera_structure('public_ssl/hostname')
      public_protocol = 'https'
    else
      public_address  = public_vip
      public_protocol = 'http'
    end

    compute_port    = '8774'
    public_base_url = "#{public_protocol}://#{public_address}:#{compute_port}"
    admin_base_url  = "http://#{admin_address}:#{compute_port}"

    ec2_port         = '8773'
    ec2_public_url   = "#{public_protocol}://#{public_address}:#{ec2_port}/services/Cloud"
    ec2_internal_url = "http://#{admin_address}:#{ec2_port}/services/Cloud"
    ec2_admin_url    = "http://#{admin_address}:#{ec2_port}/services/Admin"

    it 'class nova::keystone::auth should  contain correct *_url' do
      should contain_class('nova::keystone::auth').with(
        'public_url'       => "#{public_base_url}/v2/%(tenant_id)s",
        'public_url_v3'    => "#{public_base_url}/v3",
        'admin_url'        => "#{admin_base_url}/v2/%(tenant_id)s",
        'admin_url_v3'     => "#{admin_base_url}/v3",
        'internal_url'     => "#{admin_base_url}/v2/%(tenant_id)s",
        'internal_url_v3'  => "#{admin_base_url}/v3",
        'ec2_public_url'   => ec2_public_url,
        'ec2_admin_url'    => ec2_admin_url,
        'ec2_internal_url' => ec2_internal_url,
      )
    end
  end

  test_ubuntu_and_centos manifest
end
