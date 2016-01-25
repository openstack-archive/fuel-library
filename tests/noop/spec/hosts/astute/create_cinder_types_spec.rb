require 'spec_helper'
require 'shared-examples'
manifest = 'astute/create_cinder_types.pp'

describe manifest do
  shared_examples 'catalog' do

    volume_backend_names = hiera_hash 'storage_hash/volume_backend_names'
# TBD
#    it 'should create cinder types' do
#      should contain_create_cinder_types
#    end

  end
  test_ubuntu_and_centos manifest
end
