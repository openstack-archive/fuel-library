# ROLE: primary-controller

require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/purge_old_admin_spec.pp'

describe manifest do
  shared_examples 'catalog' do

    access_hash = Noop.hiera('old_access', [])

    if !access_hash.empty?
      it 'should purge old admin user' do
        is_expected.to contain_keystone_user(access_hash['user']).with_ensure('absent')
      end
    end
  end
  test_ubuntu_and_centos manifest
end
