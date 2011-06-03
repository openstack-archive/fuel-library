#Nova_config { target => '/tmp/nova.config' }
resources { 'nova_config':
  purge => true,
}

class { 'mysql::server':
  root_password => 'password' 
}
class { 'nova::canonical::all':
  #dhcpbridge_flagfile=/etc/nova/nova.conf
  #dhcpbridge=/usr/bin/nova-dhcpbridge
  #cc_host=192.168.25.30
  #ec2_url=http://192.168.25.30:8773/services/Cloud
  #fixed_range=10.0.0.0/32
  #network_size=255
  #FAKE_subdomain=ec2
  #routing_source_ip=192.168.25.30
  verbose => 'true',
  logdir => '/var/log/nova',
  network_manager => 'nova.network.manager.FlatManager',
  image_service => 'nova.image.glance.GlanceImageService',
  flat_network_bridge => 'xenbr0',
  glance_host => 'glance_ip_address',
  glance_port => '9292',
  allow_admin_api => 'true',
  state_path => '/var/lib/nova',
  lock_path => '/var/lock/nova',
  service_down_time => '180000000',
  host => $hostname,
  db_password => 'password',
  admin_user => 'admin',
  project_name => 'novaproject',
}
