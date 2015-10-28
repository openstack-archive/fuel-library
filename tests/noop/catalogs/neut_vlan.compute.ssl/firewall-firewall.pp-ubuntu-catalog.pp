class { 'Firewall::Linux::Debian':
  ensure  => 'running',
  enable  => 'true',
  name    => 'Firewall::Linux::Debian',
  require => 'Package[iptables]',
}

class { 'Firewall::Linux':
  ensure => 'running',
  name   => 'Firewall::Linux',
}

class { 'Firewall':
  ensure => 'running',
  name   => 'Firewall',
}

class { 'Openstack::Firewall':
  ceilometer_port              => '8777',
  corosync_input_port          => '5404',
  corosync_output_port         => '5405',
  dhcp_server_port             => '67',
  dns_server_port              => '53',
  erlang_epmd_port             => '4369',
  erlang_inet_dist_port        => '41055',
  erlang_rabbitmq_backend_port => '5673',
  erlang_rabbitmq_port         => '5672',
  galera_clustercheck_port     => '49000',
  galera_ist_port              => '4568',
  glance_api_port              => '9292',
  glance_nova_api_ec2_port     => '8773',
  glance_reg_port              => '9191',
  heat_api_cfn_port            => '8000',
  heat_api_cloudwatch_port     => '8003',
  heat_api_port                => '8004',
  http_port                    => '80',
  https_port                   => '443',
  iscsi_port                   => '3260',
  keystone_admin_port          => '35357',
  keystone_network             => '10.122.7.0/24',
  keystone_public_port         => '5000',
  libvirt_network              => '10.122.7.0/24',
  libvirt_port                 => '16509',
  memcached_port               => '11211',
  mongodb_port                 => '27017',
  mysql_backend_port           => '3307',
  mysql_gcomm_port             => '4567',
  mysql_port                   => '3306',
  name                         => 'Openstack::Firewall',
  neutron_api_port             => '9696',
  nova_api_compute_port        => '8774',
  nova_api_metadata_port       => '8775',
  nova_api_volume_port         => '8776',
  nova_vnc_ip_range            => '10.122.7.0/24',
  nova_vncproxy_port           => '6080',
  nrpe_server_port             => '5666',
  ntp_server_port              => '123',
  openvswitch_db_port          => '58882',
  pcsd_port                    => '2224',
  rsync_port                   => '873',
  ssh_port                     => '22',
  swift_account_port           => '6002',
  swift_container_port         => '6001',
  swift_object_port            => '6000',
  swift_proxy_check_port       => '49001',
  swift_proxy_port             => '8080',
  vxlan_udp_port               => '4789',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

firewall { '000 accept all icmp requests':
  action => 'accept',
  before => 'Firewall[001 accept all to lo interface]',
  name   => '000 accept all icmp requests',
  proto  => 'icmp',
}

firewall { '001 accept all to lo interface':
  action  => 'accept',
  before  => 'Firewall[002 accept related established rules]',
  iniface => 'lo',
  name    => '001 accept all to lo interface',
  proto   => 'all',
}

firewall { '002 accept related established rules':
  action => 'accept',
  name   => '002 accept related established rules',
  proto  => 'all',
  state  => ['RELATED', 'ESTABLISHED'],
}

firewall { '003 remote rabbitmq ':
  action  => 'accept',
  name    => '003 remote rabbitmq ',
  proto   => 'tcp',
  require => 'Class[Openstack::Firewall]',
  source  => '10.122.5.2',
  sport   => ['4369', '5672', '41055', '55672', '61613'],
}

firewall { '004 remote puppet ':
  action  => 'accept',
  name    => '004 remote puppet ',
  proto   => 'tcp',
  require => 'Class[Openstack::Firewall]',
  source  => '10.122.5.2',
  sport   => '8140',
}

firewall { '005 local rabbitmq admin':
  action  => 'accept',
  iniface => 'lo',
  name    => '005 local rabbitmq admin',
  proto   => 'tcp',
  require => 'Class[Openstack::Firewall]',
  sport   => '15672',
}

firewall { '006 reject non-local rabbitmq admin':
  action  => 'drop',
  name    => '006 reject non-local rabbitmq admin',
  proto   => 'tcp',
  require => 'Class[Openstack::Firewall]',
  sport   => '15672',
}

firewall { '020 ssh':
  action => 'accept',
  name   => '020 ssh',
  port   => '22',
  proto  => 'tcp',
}

firewall { '100 http':
  action => 'accept',
  name   => '100 http',
  port   => ['80', '443'],
  proto  => 'tcp',
}

firewall { '101 mysql':
  action => 'accept',
  name   => '101 mysql',
  port   => ['3306', '3307', '4567', '4568', '49000'],
  proto  => 'tcp',
}

firewall { '102 keystone':
  action      => 'accept',
  destination => '10.122.7.0/24',
  name        => '102 keystone',
  port        => ['5000', '35357'],
  proto       => 'tcp',
}

firewall { '103 swift':
  action => 'accept',
  name   => '103 swift',
  port   => ['8080', '6000', '6001', '6002', '49001'],
  proto  => 'tcp',
}

firewall { '104 glance':
  action => 'accept',
  name   => '104 glance',
  port   => ['9292', '9191', '8773'],
  proto  => 'tcp',
}

firewall { '105 nova ':
  action => 'accept',
  name   => '105 nova ',
  port   => ['8774', '8775', '8776', '6080'],
  proto  => 'tcp',
}

firewall { '106 rabbitmq ':
  action => 'accept',
  name   => '106 rabbitmq ',
  port   => ['4369', '5672', '5673', '41055'],
  proto  => 'tcp',
}

firewall { '107 memcached tcp':
  action => 'accept',
  name   => '107 memcached tcp',
  port   => '11211',
  proto  => 'tcp',
}

firewall { '107 memcached udp':
  action => 'accept',
  name   => '107 memcached udp',
  port   => '11211',
  proto  => 'udp',
}

firewall { '108 rsync':
  action => 'accept',
  name   => '108 rsync',
  port   => '873',
  proto  => 'tcp',
}

firewall { '109 iscsi ':
  action => 'accept',
  name   => '109 iscsi ',
  port   => '3260',
  proto  => 'tcp',
}

firewall { '110 neutron ':
  action => 'accept',
  name   => '110 neutron ',
  port   => '9696',
  proto  => 'tcp',
}

firewall { '111 dhcp-server':
  action => 'accept',
  name   => '111 dhcp-server',
  port   => '67',
  proto  => 'udp',
}

firewall { '111 dns-server':
  action => 'accept',
  name   => '111 dns-server',
  port   => '53',
  proto  => 'udp',
}

firewall { '112 ntp-server':
  action => 'accept',
  name   => '112 ntp-server',
  port   => '123',
  proto  => 'udp',
}

firewall { '113 corosync-input':
  action => 'accept',
  name   => '113 corosync-input',
  port   => '5404',
  proto  => 'udp',
}

firewall { '114 corosync-output':
  action => 'accept',
  name   => '114 corosync-output',
  port   => '5405',
  proto  => 'udp',
}

firewall { '115 pcsd-server':
  action => 'accept',
  name   => '115 pcsd-server',
  port   => '2224',
  proto  => 'tcp',
}

firewall { '116 openvswitch db':
  action => 'accept',
  name   => '116 openvswitch db',
  port   => '58882',
  proto  => 'udp',
}

firewall { '117 nrpe-server':
  action => 'accept',
  name   => '117 nrpe-server',
  port   => '5666',
  proto  => 'tcp',
}

firewall { '118 libvirt':
  action => 'accept',
  name   => '118 libvirt',
  port   => '16509',
  proto  => 'tcp',
  source => '10.122.7.0/24',
}

firewall { '119 libvirt migration':
  action => 'accept',
  name   => '119 libvirt migration',
  port   => '49152-49215',
  proto  => 'tcp',
}

firewall { '120 vnc ports':
  action => 'accept',
  name   => '120 vnc ports',
  port   => '5900-6100',
  proto  => 'tcp',
  source => '10.122.7.0/24',
}

firewall { '121 ceilometer':
  action => 'accept',
  name   => '121 ceilometer',
  port   => '8777',
  proto  => 'tcp',
}

firewall { '204 heat-api':
  action => 'accept',
  name   => '204 heat-api',
  port   => '8004',
  proto  => 'tcp',
}

firewall { '205 heat-api-cfn':
  action => 'accept',
  name   => '205 heat-api-cfn',
  port   => '8000',
  proto  => 'tcp',
}

firewall { '206 heat-api-cloudwatch':
  action => 'accept',
  name   => '206 heat-api-cloudwatch',
  port   => '8003',
  proto  => 'tcp',
}

firewall { '333 notrack gre':
  chain => 'PREROUTING',
  jump  => 'NOTRACK',
  name  => '333 notrack gre',
  proto => 'gre',
  table => 'raw',
}

firewall { '334 accept gre':
  action => 'accept',
  chain  => 'INPUT',
  name   => '334 accept gre',
  proto  => 'gre',
  table  => 'filter',
}

firewall { '340 vxlan_udp_port':
  action => 'accept',
  name   => '340 vxlan_udp_port',
  port   => '4789',
  proto  => 'udp',
}

firewall { '999 drop all other requests':
  action => 'drop',
  chain  => 'INPUT',
  name   => '999 drop all other requests',
  proto  => 'all',
}

package { 'iptables-persistent':
  ensure => 'present',
  name   => 'iptables-persistent',
}

package { 'iptables':
  ensure => 'present',
  name   => 'iptables',
}

service { 'iptables-persistent':
  enable    => 'true',
  hasstatus => 'true',
  name      => 'iptables-persistent',
  require   => 'Package[iptables-persistent]',
}

stage { 'main':
  name => 'main',
}

