require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-controller/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for nova auth' do
      contain_class('nova::keystone::auth')
    end

    public_vip           = Noop.hiera('public_vip')
    internal_protocol    = 'http'
    internal_address     = Noop.hiera('management_vip')
    public_ssl           = Noop.hiera_structure('public_ssl/services')

    if Noop.hiera_structure('use_ssl')
      public_protocol   = 'https'
      public_address    = Noop.hiera_structure('use_ssl/nova_public_hostname')
      internal_protocol = 'https'
      internal_address  = Noop.hiera_structure('use_ssl/nova_internal_hostname')
    elsif public_ssl
      public_protocol = 'https'
      public_address  = Noop.hiera_structure('public_ssl/hostname')
    else
      public_protocol = 'http'
      public_address  = public_vip
    end

    compute_port    = '8774'
    public_base_url = "#{public_protocol}://#{public_address}:#{compute_port}"
    admin_base_url  = "#{internal_protocol}://#{internal_address}:#{compute_port}"

    ec2_port         = '8773'
    ec2_public_url   = "#{public_protocol}://#{public_address}:#{ec2_port}/services/Cloud"
    ec2_internal_url = "#{internal_protocol}://#{internal_address}:#{ec2_port}/services/Cloud"
    ec2_admin_url    = "#{internal_protocol}://#{internal_address}:#{ec2_port}/services/Admin"

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
