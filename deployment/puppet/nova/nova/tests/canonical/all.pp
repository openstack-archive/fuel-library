Nova_config { target => '/tmp/nova.config' }
resources { 'nova_config':
  purge => true,
}

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
  root_password => 'password' 
}
class { 'nova::all':
  #dhcpbridge_flagfile=/etc/nova/nova.conf
  #dhcpbridge=/usr/bin/nova-dhcpbridge
  #verbose => true,
  #s3_host=192.168.25.30
  #rabbit_host=192.168.25.30
  #cc_host=192.168.25.30
  #ec2_url=http://192.168.25.30:8773/services/Cloud
  #fixed_range=10.0.0.0/32
  #network_size=255
  #FAKE_subdomain=ec2
  #routing_source_ip=192.168.25.30
  #verbose
  #sql_connection=mysql://root:pass@192.168.25.30/nova
  #network_manager=nova.network.manager.FlatManager
  verbose => 'true',
  logdir => '/var/log/nova',
  sql_connection => 'mysql://nova:nova@127.0.0.1/nova',
  network_manager => 'nova.network.manager.FlatManager',
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
  state_path => 'var/lib/nova',
  lock_path => 'var/lock/nova',
  service_down_time => '180000000',
  host => $ipaddress,

}
