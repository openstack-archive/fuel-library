require 'spec_helper'
require 'shared-examples'
manifest = 'glance/glance.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.
    glance_config = Noop.hiera_structure 'glance'
    storage_config = Noop.hiera_structure 'storage'
    max_pool_size = Noop.hiera('max_pool_size')
    max_overflow = Noop.hiera('max_overflow')
    max_retries = '-1'
    use_syslog = Noop.hiera('use_syslog')
    if glance_config && glance_config.has_key?('pipeline')
       pipeline = glance_config['pipeline']
    else
       pipeline = 'keystone'
    end

    it 'should declare glance classes' do
      should contain_class('glance::api').with('pipeline' => pipeline)
      should contain_class('glance::registry')
      should contain_class('glance::notify::rabbitmq')
    end

    it 'should configure glance api config' do
      should contain_glance_api_config('database/sql_max_pool_size').with_value(max_pool_size)
      should contain_glance_api_config('database/sql_max_overflow').with_value(max_overflow)
      should contain_glance_api_config('database/sql_max_retries').with_value(max_retries)
      should contain_glance_api_config('DEFAULT/delayed_delete').with_value('False')
      should contain_glance_api_config('DEFAULT/scrub_time').with_value('43200')
      should contain_glance_api_config('DEFAULT/scrubber_datadir').with_value('/var/lib/glance/scrubber')
      should contain_glance_api_config('keystone_authtoken/signing_dir').with_value('/tmp/keystone-signing-glance')
      should contain_glance_api_config('keystone_authtoken/token_cache_time').with_value('-1')
    end

    it 'should configure glance cache config' do
      should contain_glance_cache_config('DEFAULT/use_syslog').with_value(use_syslog)
      should contain_glance_cache_config('DEFAULT/image_cache_dir').with_value('/var/lib/glance/image-cache/')
      should contain_glance_cache_config('DEFAULT/log_file').with_value('/var/log/glance/image-cache.log')
      should contain_glance_cache_config('DEFAULT/image_cache_stall_time').with_value('86400')

      if glance_config && glance_config.has_key?('image_cache_max_size')
        glance_image_cache_max_size = glance_config['image_cache_max_size']
        should contain_glance_cache_config('DEFAULT/image_cache_max_size').with_value(glance_image_cache_max_size)
      end
    end

    it 'should configure glance registry config' do
      should contain_glance_registry_config('database/sql_max_pool_size').with_value(max_pool_size)
      should contain_glance_registry_config('database/sql_max_overflow').with_value(max_overflow)
      should contain_glance_registry_config('database/sql_max_retries').with_value(max_retries)
      should contain_glance_registry_config('keystone_authtoken/signing_dir').with_value('/tmp/keystone-signing-glance')
    end

    if use_syslog
      it 'should configure rfc format' do
        should contain_glance_api_config('DEFAULT/use_syslog_rfc_format').with_value('true')
        should contain_glance_cache_config('DEFAULT/use_syslog_rfc_format').with_value('true')
        should contain_glance_registry_config('DEFAULT/use_syslog_rfc_format').with_value('true')
      end
    end

    if storage_config && storage_config.has_key?('images_ceph') && storage_config['images_ceph']
      let :params do { :glance_backend => 'ceph', } end
      it 'should declare ceph backend' do
        should contain_class('glance::backend::rbd')
      end
    elsif storage_config && storage_config.has_key?('images_vcenter') && storage_config['images_vcenter']
      let :params do { :glance_backend => 'vmware', } end
      it 'should declare vmware backend' do
        should contain_class('glance::backend::vsphere')
      end
    else
      let :params do { :glance_backend => 'swift', } end
      it 'should declare swift backend' do
        should contain_class('glance::backend::swift')
      end
    end
  end

  test_ubuntu_and_centos manifest
end

