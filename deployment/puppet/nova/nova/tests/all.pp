stage { 'repo-setup':
  before => Stage['main'],
}
class { 'apt':
  disable_keys => true, 
  #always_apt_update => true,
  stage => 'repo-setup',
}
class { 'nova::repo':
  stage => 'repo-setup',
}
class { 'mysql::server':
  mysql_root_pw => 'password' 
}
class { 'nova::all':
  verbose => 'true',
  logdir => '/var/log/nova',
  sql_connection => 'mysql://root:<password>@127.0.0.1/nova',
  network_manager => 'nova.network.manager.FlatManager',
  image_service => 'nova.image.glance.GlanceImageService',
  flat_network_bridge => 'xenbr0',
  glance_host => '<glance ip address>',
  glance_port => '9292',
  allow_admin_api => 'true',
  rabbit_host => 'rabbit ip address>',
  rabbit_password => 'rabbit password>',
  rabbit_port => '5672',
  rabbit_userid => 'rabbit user>',
  rabbit_virtual_host => '/',
  state_path => 'var/lib/nova',
  lock_path => 'var/lock/nova',
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
  host => $ipaddress,
  connection_type => 'xenapi',
  xenapi_connection_url => 'https://<XenServer IP>',
  xenapi_connection_username => 'root',
  xenapi_connection_password => 'password',
  xenapi_inject_image => 'false',
}

