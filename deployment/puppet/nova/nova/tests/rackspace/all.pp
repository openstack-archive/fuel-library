Nova_config { target => '/tmp/nova.config' }
resources { 'nova_config':
  purge => true,
}

class { 'nova::rackspace::all':
  verbose => 'true',
  sql_connection => 'mysql://root:<password>@127.0.0.1/nova',
  image_service => 'nova.image.glance.GlanceImageService',
  flat_network_bridge => 'xenbr0',
  glance_host => 'glance_ip_address',
  glance_port => '9292',
  allow_admin_api => 'true',
  rabbit_host => 'rabbit_ip_address',
  rabbit_password => 'rabbitpassword',
  rabbit_port => '5672',
  rabbit_userid => 'rabbit_user',
  rabbit_virtual_host => '/',
  service_down_time => '180000000',
  quota_instances => '1000000',
  quota_cores => '1000000',
  quota_volumes => '1000000',
  quota_gigabytes => '1000000',
  quota_floating_ips => '1000000',
  quota_metadata_items => '1000000',
  quota_max_injected_files => '1000000',
  quota_max_injected_file_content_bytes => '1000000',
  quota_max_injected_file_path_bytes => '1000000',
  host => $hostname,
  xenapi_connection_url => 'https://<XenServer_IP>',
  xenapi_connection_username => 'root',
  xenapi_connection_password => 'password',
  xenapi_inject_image => 'false',
}
