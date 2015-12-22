require 'spec_helper'
require 'shared-examples'
manifest = 'glance/glance.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.
    glance_config = Noop.hiera_structure 'glance'
    storage_config = Noop.hiera_structure 'storage'
    let(:max_pool_size) { Noop.hiera('max_pool_size') }
    let(:max_overflow) { Noop.hiera('max_overflow') }
    let(:max_retries) { Noop.hiera('max_retries') }
    let(:idle_timeout) { Noop.hiera('idle_timeout') }
    use_syslog = Noop.hiera('use_syslog', 'true')
    use_stderr = Noop.hiera('use_stderr', 'false')
    region = Noop.hiera('region', 'RegionOne')
    ironic_enabled = Noop.hiera_structure('ironic/enabled', false)
    default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
    default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='
    primary_controller = Noop.hiera 'primary_controller'
    if glance_config && glance_config.has_key?('pipeline')
       pipeline = glance_config['pipeline']
    else
       pipeline = 'keystone'
    end

    it 'should declare glance classes' do
      should contain_class('glance::api').with('pipeline' => pipeline)
      should contain_class('glance::registry').with('sync_db' => primary_controller)
      should contain_class('glance::notify::rabbitmq')
    end

    it 'should configure glance api config' do
      should contain_glance_api_config('database/max_pool_size').with_value(max_pool_size)
      should contain_glance_api_config('DEFAULT/use_stderr').with_value(use_stderr)
      should contain_glance_api_config('database/max_overflow').with_value(max_overflow)
      should contain_glance_api_config('database/max_retries').with_value(max_retries)
      should contain_glance_api_config('database/idle_timeout').with_value(idle_timeout)
      should contain_glance_api_config('DEFAULT/delayed_delete').with_value('False')
      should contain_glance_api_config('DEFAULT/scrub_time').with_value('43200')
      should contain_glance_api_config('DEFAULT/scrubber_datadir').with_value('/var/lib/glance/scrubber')
      should contain_glance_api_config('DEFAULT/auth_region').with_value(region)
      should contain_glance_api_config('DEFAULT/os_region_name').with_value(region)
      should contain_glance_api_config('glance_store/os_region_name').with_value(region)
      should contain_glance_api_config('keystone_authtoken/signing_dir').with_value('/tmp/keystone-signing-glance')
      should contain_glance_api_config('keystone_authtoken/token_cache_time').with_value('-1')
    end

    if $glance_backend == 'rbd'
      it 'should configure rados_connect_timeout' do
        should contain_glance_api_config('glance_store/rados_connect_timeout').with_value('30')
      end
    end

    it 'should configure glance cache config' do
      should contain_glance_cache_config('DEFAULT/use_syslog').with_value(use_syslog)
      should contain_glance_cache_config('DEFAULT/image_cache_dir').with_value('/var/lib/glance/image-cache/')
      should contain_glance_cache_config('DEFAULT/log_file').with_value('/var/log/glance/image-cache.log')
      should contain_glance_cache_config('DEFAULT/image_cache_stall_time').with_value('86400')
      should contain_glance_cache_config('DEFAULT/os_region_name').with_value(region)
      should contain_glance_cache_config('glance_store/os_region_name').with_value(region)
      if glance_config && glance_config.has_key?('image_cache_max_size')
        glance_image_cache_max_size = glance_config['image_cache_max_size']
        should contain_glance_cache_config('DEFAULT/image_cache_max_size').with_value(glance_image_cache_max_size)
      end
    end

    it 'should configure glance registry config' do
      should contain_glance_registry_config('DEFAULT/use_stderr').with_value(use_stderr)
      should contain_glance_registry_config('database/max_pool_size').with_value(max_pool_size)
      should contain_glance_registry_config('database/max_overflow').with_value(max_overflow)
      should contain_glance_registry_config('database/max_retries').with_value(max_retries)
      should contain_glance_registry_config('glance_store/os_region_name').with_value(region)
      should contain_glance_registry_config('keystone_authtoken/signing_dir').with_value('/tmp/keystone-signing-glance')
    end

    if use_syslog
      it 'should configure rfc format' do
        should contain_glance_api_config('DEFAULT/use_syslog_rfc_format').with_value('true')
        should contain_glance_cache_config('DEFAULT/use_syslog_rfc_format').with_value('true')
        should contain_glance_registry_config('DEFAULT/use_syslog_rfc_format').with_value('true')
      end
    end

    it 'should configure default_log_levels' do
      should contain_glance_api_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
      should contain_glance_registry_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
    end

    if storage_config && storage_config.has_key?('images_ceph') && storage_config['images_ceph']
      if glance_config && glance_config.has_key?('show_image_direct_url')
        show_image_direct_url = glance_config['show_image_direct_url']
      else
        show_image_direct_url = true
      end
      if ironic_enabled
        it 'should declare swift backend' do
          should contain_class('glance::backend::swift')
        end
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
        should contain_class('glance::backend::swift').with('swift_store_region' => region)
      end
      it 'should configure show_image_direct_url' do
        should contain_glance_api_config('DEFAULT/show_image_direct_url').with_value(show_image_direct_url)
      end
    end
  end

  test_ubuntu_and_centos manifest
end

