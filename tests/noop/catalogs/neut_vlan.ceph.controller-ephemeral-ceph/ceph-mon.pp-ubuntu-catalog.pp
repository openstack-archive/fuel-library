ceph_conf { 'client/rbd_cache':
  name  => 'client/rbd_cache',
  value => 'true',
}

ceph_conf { 'client/rbd_cache_writethrough_until_flush':
  name  => 'client/rbd_cache_writethrough_until_flush',
  value => 'true',
}

ceph_conf { 'global/auth_supported':
  name  => 'global/auth_supported',
  value => 'cephx',
}

ceph_conf { 'global/cluster_network':
  name  => 'global/cluster_network',
  value => '10.122.14.0/24',
}

ceph_conf { 'global/log_to_syslog':
  name  => 'global/log_to_syslog',
  value => 'true',
}

ceph_conf { 'global/log_to_syslog_facility':
  name  => 'global/log_to_syslog_facility',
  value => 'LOG_LOCAL0',
}

ceph_conf { 'global/log_to_syslog_level':
  name  => 'global/log_to_syslog_level',
  value => 'info',
}

ceph_conf { 'global/mon_host':
  before => 'Exec[reload Ceph for HA]',
  name   => 'global/mon_host',
  value  => '10.122.12.3',
}

ceph_conf { 'global/mon_initial_members':
  before => 'Exec[reload Ceph for HA]',
  name   => 'global/mon_initial_members',
  value  => 'node-1',
}

ceph_conf { 'global/osd_journal_size':
  name  => 'global/osd_journal_size',
  value => '2048',
}

ceph_conf { 'global/osd_max_backfills':
  name  => 'global/osd_max_backfills',
  value => '1',
}

ceph_conf { 'global/osd_mkfs_type':
  name  => 'global/osd_mkfs_type',
  value => 'xfs',
}

ceph_conf { 'global/osd_pool_default_min_size':
  name  => 'global/osd_pool_default_min_size',
  value => '1',
}

ceph_conf { 'global/osd_pool_default_pg_num':
  name  => 'global/osd_pool_default_pg_num',
  value => '64',
}

ceph_conf { 'global/osd_pool_default_pgp_num':
  name  => 'global/osd_pool_default_pgp_num',
  value => '64',
}

ceph_conf { 'global/osd_pool_default_size':
  name  => 'global/osd_pool_default_size',
  value => '2',
}

ceph_conf { 'global/osd_recovery_max_active':
  name  => 'global/osd_recovery_max_active',
  value => '1',
}

ceph_conf { 'global/public_network':
  name  => 'global/public_network',
  value => '10.122.12.0/24',
}

class { 'Ceph::Conf':
  before        => 'Class[Ceph::Mon]',
  mon_addr      => '10.122.12.3',
  name          => 'Ceph::Conf',
  node_hostname => 'node-1',
}

class { 'Ceph::Mon':
  before           => 'Service[ceph]',
  mon_addr         => '10.122.12.3',
  mon_hosts        => 'node-1',
  mon_ip_addresses => '10.122.12.3',
  name             => 'Ceph::Mon',
  node_hostname    => 'node-1',
}

class { 'Ceph::Params':
  before => 'Class[Ceph::Conf]',
  name   => 'Ceph::Params',
}

class { 'Ceph::Ssh':
  before => 'Class[Ceph::Conf]',
  name   => 'Ceph::Ssh',
}

class { 'Ceph':
  auth_supported                     => 'cephx',
  cinder_backup_pool                 => 'backups',
  cinder_backup_user                 => 'backups',
  cinder_pool                        => 'volumes',
  cinder_user                        => 'volumes',
  cluster_network                    => '10.122.14.0/24',
  cluster_node_address               => '10.122.11.3',
  compute_pool                       => 'compute',
  compute_user                       => 'compute',
  ephemeral_ceph                     => 'true',
  glance_api_version                 => '2',
  glance_backend                     => 'swift',
  glance_pool                        => 'images',
  glance_user                        => 'images',
  libvirt_images_type                => 'rbd',
  mon_addr                           => '10.122.12.3',
  mon_hosts                          => 'node-1',
  mon_ip_addresses                   => '10.122.12.3',
  name                               => 'Ceph',
  node_hostname                      => 'node-1',
  osd_devices                        => [],
  osd_journal_size                   => '2048',
  osd_max_backfills                  => '1',
  osd_mkfs_type                      => 'xfs',
  osd_pool_default_min_size          => '1',
  osd_pool_default_pg_num            => '64',
  osd_pool_default_pgp_num           => '64',
  osd_pool_default_size              => '2',
  osd_recovery_max_active            => '1',
  primary_mon                        => 'node-1',
  public_network                     => '10.122.12.0/24',
  rbd_cache                          => 'true',
  rbd_cache_writethrough_until_flush => 'true',
  rbd_secret_uuid                    => 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
  rgw_adm_ip                         => '10.122.12.2',
  rgw_data                           => '/var/lib/ceph/radosgw',
  rgw_dns_name                       => '*.pp',
  rgw_host                           => 'node-1',
  rgw_int_ip                         => '10.122.12.2',
  rgw_ip                             => '0.0.0.0',
  rgw_keyring_path                   => '/etc/ceph/keyring.radosgw.gateway',
  rgw_keystone_accepted_roles        => '_member_, Member, admin, swiftoperator',
  rgw_keystone_admin_token           => 'n7tfrNvt',
  rgw_keystone_revocation_interval   => '60',
  rgw_keystone_token_cache_size      => '10',
  rgw_keystone_url                   => '10.122.11.3:35357',
  rgw_log_file                       => '/var/log/ceph/radosgw.log',
  rgw_nss_db_path                    => '/etc/ceph/nss',
  rgw_port                           => '6780',
  rgw_print_continue                 => 'true',
  rgw_pub_ip                         => '10.122.11.3',
  rgw_socket_path                    => '/tmp/radosgw.sock',
  rgw_use_keystone                   => 'true',
  rgw_use_pki                        => 'false',
  show_image_direct_url              => 'True',
  swift_endpoint_port                => '8080',
  syslog_log_facility                => 'LOG_LOCAL0',
  syslog_log_level                   => 'info',
  use_rgw                            => 'false',
  use_ssl                            => 'false',
  use_syslog                         => 'true',
  volume_driver                      => 'cinder.volume.drivers.rbd.RBDDriver',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

exec { 'Wait for Ceph quorum':
  before    => 'Exec[ceph-deploy gatherkeys]',
  command   => 'ps ax|grep -vq ceph-create-keys',
  cwd       => '/root',
  path      => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  returns   => '0',
  tries     => '60',
  try_sleep => '1',
}

exec { 'ceph-deploy gatherkeys':
  before  => ['Ceph_conf[global/mon_host]', 'Ceph_conf[global/mon_initial_members]'],
  command => 'ceph-deploy gatherkeys node-1',
  creates => ['/root/ceph.bootstrap-mds.keyring', '/root/ceph.bootstrap-osd.keyring', '/root/ceph.client.admin.keyring'],
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
}

exec { 'ceph-deploy mon create':
  before    => 'Exec[Wait for Ceph quorum]',
  command   => 'ceph-deploy mon create node-1:10.122.12.3',
  cwd       => '/root',
  logoutput => 'true',
  path      => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  unless    => 'ceph mon dump | grep -E '^[0-9]+: +10.122.12.3:.* mon\.node-1$'',
}

exec { 'ceph-deploy new':
  before    => 'File[/root/ceph.conf]',
  command   => 'ceph-deploy new node-1:10.122.12.3',
  creates   => '/etc/ceph/ceph.conf',
  cwd       => '/etc/ceph',
  logoutput => 'true',
  path      => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
}

exec { 'reload Ceph for HA':
  command   => 'service ceph reload',
  cwd       => '/root',
  path      => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  subscribe => ['Ceph_conf[global/mon_host]', 'Ceph_conf[global/mon_initial_members]'],
}

file { '/root/.ssh/config':
  content => 'Host *
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
',
  mode    => '0600',
  path    => '/root/.ssh/config',
}

file { '/root/ceph.conf':
  ensure => 'link',
  before => 'File[/root/ceph.mon.keyring]',
  path   => '/root/ceph.conf',
  target => '/etc/ceph/ceph.conf',
}

file { '/root/ceph.mon.keyring':
  ensure => 'link',
  before => ['Ceph_conf[global/auth_supported]', 'Ceph_conf[global/osd_journal_size]', 'Ceph_conf[global/osd_mkfs_type]', 'Ceph_conf[global/osd_pool_default_size]', 'Ceph_conf[global/osd_pool_default_min_size]', 'Ceph_conf[global/osd_pool_default_pg_num]', 'Ceph_conf[global/osd_pool_default_pgp_num]', 'Ceph_conf[global/cluster_network]', 'Ceph_conf[global/public_network]', 'Ceph_conf[global/log_to_syslog]', 'Ceph_conf[global/log_to_syslog_level]', 'Ceph_conf[global/log_to_syslog_facility]', 'Ceph_conf[global/osd_max_backfills]', 'Ceph_conf[global/osd_recovery_max_active]', 'Ceph_conf[client/rbd_cache]', 'Ceph_conf[client/rbd_cache_writethrough_until_flush]', 'Ceph_conf[global/mon_host]', 'Ceph_conf[global/mon_initial_members]'],
  path   => '/root/ceph.mon.keyring',
  target => '/etc/ceph/ceph.mon.keyring',
}

firewall { '010 ceph-mon allow':
  action => 'accept',
  before => 'Exec[ceph-deploy mon create]',
  chain  => 'INPUT',
  dport  => '6789',
  name   => '010 ceph-mon allow',
  proto  => 'tcp',
}

install_ssh_keys { 'root_ssh_keys_for_ceph':
  ensure           => 'present',
  authorized_keys  => 'authorized_keys',
  before           => 'File[/root/.ssh/config]',
  name             => 'root_ssh_keys_for_ceph',
  private_key_name => 'id_rsa',
  private_key_path => '/var/lib/astute/ceph/ceph',
  public_key_name  => 'id_rsa.pub',
  public_key_path  => '/var/lib/astute/ceph/ceph.pub',
  user             => 'root',
}

package { 'ceph-deploy':
  ensure => 'installed',
  name   => 'ceph-deploy',
}

package { 'ceph':
  ensure => 'installed',
  name   => 'ceph',
  notify => 'Service[ceph]',
}

service { 'ceph':
  ensure  => 'running',
  enable  => 'true',
  name    => 'ceph-all',
  require => 'Class[Ceph::Conf]',
}

stage { 'main':
  name => 'main',
}

