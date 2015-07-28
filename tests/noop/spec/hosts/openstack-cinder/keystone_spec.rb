require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-cinder/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for cinder auth' do
      contain_class('cinder::keystone::auth')
    end

  public_vip           = Noop.hiera('public_vip')
  public_ssl           = Noop.hiera_structure('public_ssl/services')

  if public_ssl
    public_address  = Noop.hiera_structure('public_ssl/hostname')
  else
    public_address  = public_vip
  end

  end

  test_ubuntu_and_centos manifest
end
