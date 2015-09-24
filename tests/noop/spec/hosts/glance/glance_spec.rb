require 'spec_helper'
require 'shared-examples'
manifest = 'glance/glance.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.
    glance_config = Noop.hiera_structure 'glance'
    storage_config = Noop.hiera_structure 'storage'
    
    if storage_config && storage_config.has_key?('images_ceph') && storage_config['images_ceph']
      if glance_config && glance_config.has_key?('show_image_direct_url')
        show_image_direct_url = glance_config['show_image_direct_url']
      else
        show_image_direct_url = true
      end
      let :params do { :glance_backend => 'ceph', } end
      it 'should declare ceph backend' do
        should contain_class('glance::backend::rbd')
      end
      it 'should configure show_image_direct_url' do
        should contain_glance_api_config('DEFAULT/show_image_direct_url').with_value(show_image_direct_url)
      end
    elsif storage_config && storage_config.has_key?('images_vcenter') && storage_config['images_vcenter']
      if glance_config && glance_config.has_key?('show_image_direct_url')
        show_image_direct_url = glance_config['show_image_direct_url']
      else
        show_image_direct_url = true
      end
      let :params do { :glance_backend => 'vmware', } end
      it 'should declare vmware backend' do
        should contain_class('glance::backend::vsphere')
      end
      it 'should configure show_image_direct_url' do
        should contain_glance_api_config('DEFAULT/show_image_direct_url').with_value(show_image_direct_url)
      end
    else
      if glance_config && glance_config.has_key?('show_image_direct_url')
        show_image_direct_url = glance_config['show_image_direct_url']
      else
        show_image_direct_url = false
      end
      let :params do { :glance_backend => 'swift', } end
      it 'should declare swift backend' do
        should contain_class('glance::backend::swift')
      end
      it 'should configure show_image_direct_url' do
        should contain_glance_api_config('DEFAULT/show_image_direct_url').with_value(show_image_direct_url)
      end
    end
  end

  test_ubuntu_and_centos manifest
end

