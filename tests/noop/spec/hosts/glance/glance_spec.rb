# ROLE: primary-controller
# ROLE: controller
# FIXME: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# FIXME: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'glance/glance.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.
    workers_max = Noop.hiera 'workers_max'
    glance_config = Noop.hiera_structure 'glance'
    storage_config = Noop.hiera_structure 'storage'
    max_pool_size = Noop.hiera('max_pool_size')
    max_overflow = Noop.hiera('max_overflow')
    max_retries = '-1'
    use_syslog = Noop.hiera('use_syslog', 'true')
    use_stderr = Noop.hiera('use_stderr', 'false')
    region = Noop.hiera('region', 'RegionOne')
    ironic_enabled = Noop.hiera_structure('ironic/enabled', false)
    default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
    default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='
    primary_controller = Noop.hiera 'primary_controller'
    kombu_compression = Noop.hiera 'kombu_compression', ''
    if glance_config && glance_config.has_key?('pipeline')
       pipeline = glance_config['pipeline']
    else
       pipeline = 'keystone'
    end
    database_vip = Noop.hiera('database_vip')
    glance_db_type = Noop.hiera_structure 'glance/db_type', 'mysql+pymysql'
    glance_db_password = Noop.hiera_structure 'glance/db_password', 'glance'
    glance_db_user = Noop.hiera_structure 'glance/db_user', 'glance'
    glance_db_name = Noop.hiera_structure 'glance/db_name', 'glance'
    #vCenter
    glance_vc_host = Noop.hiera_structure 'glance/vc_host', '172.16.0.254'
    glance_vc_user = Noop.hiera_structure 'glance/vc_user', 'administrator@vsphere.local'
    glance_vc_password = Noop.hiera_structure 'glance/vc_password', 'Qwer!1234'
    glance_vc_datacenter = Noop.hiera_structure 'glance/vc_datacenter', 'Datacenter'
    glance_vc_datastore = Noop.hiera_structure 'glance/vc_datastore', 'nfs'
    glance_vc_image_dir = Noop.hiera_structure 'glance/vc_image_dir'
    glance_vc_ca_file = Noop.hiera_structure 'glance/vc_ca_file', {'content' => 'RSA', 'name' => 'vcenter-ca.pem'}

    let(:ceilometer_hash) { Noop.hiera_structure 'ceilometer' }

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

    let(:internal_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http' }

    let(:internal_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[Noop.hiera('service_endpoint', ''), Noop.hiera('management_vip')] }

    let(:admin_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','protocol','http' }

    let(:admin_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','hostname',[Noop.hiera('service_endpoint', ''), Noop.hiera('management_vip')] }

    let(:auth_uri) { "#{internal_auth_protocol}://#{internal_auth_address}:5000/" }

    let(:identity_uri) { "#{admin_auth_protocol}://#{admin_auth_address}:35357/" }

    it 'should select right protocols and addresses for auth' do
      should contain_class('glance::api').with(
        'auth_uri'     => auth_uri,
        'identity_uri' => identity_uri,
      )
    end

    it 'should configure workers for API, registry services' do
      fallback_workers = [[facts[:processorcount].to_i, 2].max, workers_max.to_i].min
      service_workers = glance_config.fetch('glance_workers', fallback_workers)
      should contain_glance_api_config('DEFAULT/workers').with(:value => service_workers)
      should contain_glance_registry_config('DEFAULT/workers').with(:value => service_workers)
    end

    it 'should declare glance classes' do
      should contain_class('glance::api').with('pipeline' => pipeline)
      should contain_class('glance::registry').with('sync_db' => primary_controller)
      should contain_class('glance::glare').with('pipeline' => pipeline)
      should contain_class('glance::notify::rabbitmq')
    end

    it 'should configure the database connection string' do
        if facts[:os_package_type] == 'debian'
            extra_params = '?charset=utf8&read_timeout=60'
        else
            extra_params = '?charset=utf8'
        end

        db_connection = "#{glance_db_type}://#{glance_db_user}:#{glance_db_password}@#{database_vip}/#{glance_db_name}#{extra_params}"
        should contain_class('glance::api').with(:database_connection => db_connection)
        should contain_class('glance::registry').with(:database_connection => db_connection)
        should contain_class('glance::glare::db').with(:database_connection => db_connection)
    end

    it 'should configure glance api config' do
      should contain_glance_api_config('database/max_pool_size').with_value(max_pool_size)
      should contain_glance_api_config('DEFAULT/use_stderr').with_value(use_stderr)
      should contain_glance_api_config('database/max_overflow').with_value(max_overflow)
      should contain_glance_api_config('database/max_retries').with_value(max_retries)
      should contain_glance_api_config('DEFAULT/delayed_delete').with_value(false)
      should contain_glance_api_config('DEFAULT/scrub_time').with_value('43200')
      should contain_glance_api_config('DEFAULT/scrubber_datadir').with_value('/var/lib/glance/scrubber')
      should contain_glance_api_config('DEFAULT/auth_region').with_value(region)
      should contain_glance_api_config('glance_store/os_region_name').with_value(region)
      should contain_glance_api_config('keystone_authtoken/signing_dir').with_value('/tmp/keystone-signing-glance')
      should contain_glance_api_config('keystone_authtoken/token_cache_time').with_value('-1')
      should contain_glance_api_config('keystone_authtoken/auth_type').with_value('password')
      should contain_glance_api_config('keystone_authtoken/auth_url').with_value(identity_uri)
      should contain_glance_api_config('keystone_authtoken/username').with_value(glance_config.fetch('user', 'glance'))
      should contain_glance_api_config('keystone_authtoken/password').with_value(glance_config.fetch('user_password'))
      should contain_glance_api_config('keystone_authtoken/project_name').with_value(glance_config.fetch('project_name', 'services'))
    end

    it 'should configure glance glare config' do
      should contain_glance_glare_config('database/max_pool_size').with_value(max_pool_size)
      should contain_glance_glare_config('DEFAULT/use_stderr').with_value(use_stderr)
      should contain_glance_glare_config('database/max_overflow').with_value(max_overflow)
      should contain_glance_glare_config('database/max_retries').with_value(max_retries)
      should contain_glance_glare_config('DEFAULT/auth_region').with_value(region)
      should contain_glance_glare_config('glance_store/os_region_name').with_value(region)
      should contain_glance_glare_config('keystone_authtoken/signing_dir').with_value('/tmp/keystone-signing-glance')
      should contain_glance_glare_config('keystone_authtoken/token_cache_time').with_value('-1')
    end

    if $glance_backend == 'rbd'
      it 'should configure rados_connect_timeout' do
        should contain_glance_api_config('glance_store/rados_connect_timeout').with_value('30')
      end
    end

    it 'should configure glance cache config' do
      should contain_glance_cache_config('DEFAULT/use_syslog').with_value(use_syslog)
      should contain_glance_cache_config('DEFAULT/image_cache_dir').with_value('/var/lib/glance/image-cache/')
      should contain_glance_cache_config('DEFAULT/log_file').with_value('/var/log/glance/cache.log')
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
        should contain_glance_glare_config('DEFAULT/use_syslog_rfc_format').with_value('true')
      end
    end

    it 'should configure default_log_levels' do
      should contain_glance_api_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
      should contain_glance_registry_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
      should contain_glance_glare_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
    end

    if storage_config && storage_config.has_key?('images_ceph') && storage_config['images_ceph']
      if glance_config && glance_config.has_key?('show_image_direct_url')
        show_image_direct_url = glance_config['show_image_direct_url']
      else
        show_image_direct_url = true
      end
      if ironic_enabled
        it 'should declare swift backend' do
          should contain_class('glance::backend::swift').with(:glare_enabled => true)
        end
      end
      let :params do { :glance_backend => 'ceph', } end
      it 'should declare ceph backend' do
        should contain_class('glance::backend::rbd').with(:glare_enabled => true)
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
        should contain_class('glance::backend::vsphere').with(:vcenter_host => glance_vc_host)
        should contain_class('glance::backend::vsphere').with(:vcenter_user => glance_vc_user)
        should contain_class('glance::backend::vsphere').with(:vcenter_password => glance_vc_password)
        should contain_class('glance::backend::vsphere').with(:vcenter_datastores => "#{glance_vc_datacenter}:#{glance_vc_datastore}")
        should contain_class('glance::backend::vsphere').with(:vcenter_image_dir => glance_vc_image_dir)
        should contain_class('glance::backend::vsphere').with(:vcenter_api_retry_count => '20')
        should contain_class('glance::backend::vsphere').with(:vcenter_ca_file => "/etc/glance/#{glance_vc_ca_file['name']}")
        should contain_class('glance::backend::vsphere').with(:glare_enabled => true)
      end
      it 'should configure vmware_server_host setting' do
        should contain_glance_api_config('glance_store/vmware_server_host').with_value(glance_vc_host)
        should contain_glance_glare_config('glance_store/vmware_server_host').with_value(glance_vc_host)
      end
      it 'should configure vmware_server_username setting' do
        should contain_glance_api_config('glance_store/vmware_server_username').with_value(glance_vc_user)
        should contain_glance_glare_config('glance_store/vmware_server_username').with_value(glance_vc_user)
      end
      it 'should configure vmware_server_password setting' do
        should contain_glance_api_config('glance_store/vmware_server_password').with_value(glance_vc_password)
        should contain_glance_glare_config('glance_store/vmware_server_password').with_value(glance_vc_password)
      end
      it 'should configure vmware_datastores setting' do
        should contain_glance_api_config('glance_store/vmware_datastores').with_value("#{glance_vc_datacenter}:#{glance_vc_datastore}")
        should contain_glance_glare_config('glance_store/vmware_datastores').with_value("#{glance_vc_datacenter}:#{glance_vc_datastore}")
      end
      it 'should configure vmware_store_image_dir setting' do
        should contain_glance_api_config('glance_store/vmware_store_image_dir').with_value(glance_vc_image_dir)
        should contain_glance_glare_config('glance_store/vmware_store_image_dir').with_value(glance_vc_image_dir)
      end
      it 'should configure vmware_api_retry_count setting' do
        should contain_glance_api_config('glance_store/vmware_api_retry_count').with_value('20')
        should contain_glance_glare_config('glance_store/vmware_api_retry_count').with_value('20')
      end
      it 'should configure vmware_insecure setting' do
        should contain_glance_api_config('glance_store/vmware_insecure').with_value('True')
        should contain_glance_glare_config('glance_store/vmware_insecure').with_value('True')
      end
      it 'should configure vmware_ca_file setting' do
        should contain_glance_api_config('glance_store/vmware_ca_file').with_value("/etc/glance/#{glance_vc_ca_file['name']}")
        should contain_glance_glare_config('glance_store/vmware_ca_file').with_value("/etc/glance/#{glance_vc_ca_file['name']}")
      end
      it 'should configure default_store setting' do
        should contain_glance_api_config('glance_store/default_store').with_value('vsphere')
        should contain_glance_glare_config('glance_store/default_store').with_value('vsphere')
      end
      it 'should configure stores setting' do
        should contain_glance_api_config('glance_store/stores').with_value('glance.store.vmware_datastore.Store,glance.store.http.Store')
        should contain_glance_glare_config('glance_store/stores').with_value('glance.store.vmware_datastore.Store,glance.store.http.Store')
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
        should contain_class('glance::backend::swift').with(
          'swift_store_region'       => region,
          'swift_store_auth_version' => '3',
          'swift_store_auth_address' => "#{auth_uri}/v3",
        )
      end
      it 'should configure show_image_direct_url' do
        should contain_glance_api_config('DEFAULT/show_image_direct_url').with_value(show_image_direct_url)
      end
    end

    it 'should contain oslo_messaging_notifications "driver" option' do
      should contain_glance_api_config('oslo_messaging_notifications/driver').with(:value => ceilometer_hash['notification_driver'])
      should contain_glance_registry_config('oslo_messaging_notifications/driver').with(:value => ceilometer_hash['notification_driver'])
    end

      it 'should properly configure rabbit queue' do
        should contain_glance_api_config('DEFAULT/rpc_backend').with(:value => 'rabbit')
        should contain_glance_registry_config('DEFAULT/rpc_backend').with(:value => 'rabbit')

        should contain_glance_api_config('oslo_messaging_rabbit/default_notification_exchange').with(:value => 'glance')
        should contain_glance_registry_config('oslo_messaging_rabbit/default_notification_exchange').with(:value => 'glance')
        should contain_glance_api_config('oslo_messaging_notifications/topics').with(:value => 'notifications')
        should contain_glance_registry_config('oslo_messaging_notifications/topics').with(:value => 'notifications')
      end

    if ['gzip', 'bz2'].include?(kombu_compression)
      it 'should configure kombu compression' do
        should contain_glance_api_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
        should contain_glance_registry_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
        should contain_glance_glare_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
      end
    end
  end

  test_ubuntu_and_centos manifest
end

