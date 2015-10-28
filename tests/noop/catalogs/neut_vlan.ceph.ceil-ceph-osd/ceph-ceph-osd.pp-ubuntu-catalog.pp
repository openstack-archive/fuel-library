ceph_conf { 'global/cluster_network':
  before => 'File[/root/ceph.conf]',
  name   => 'global/cluster_network',
  value  => '192.168.1.0/24',
}

ceph_conf { 'global/public_network':
  before => 'File[/root/ceph.conf]',
  name   => 'global/public_network',
  value  => '192.168.0.0/24',
}

class { 'Ceph::Conf':
  name          => 'Ceph::Conf',
  node_hostname => 'node-124',
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
  cluster_network                    => '192.168.1.0/24',
  cluster_node_address               => '172.16.0.3',
  compute_pool                       => 'compute',
  compute_user                       => 'compute',
  ephemeral_ceph                     => 'false',
  glance_api_version                 => '2',
  glance_backend                     => 'ceph',
  glance_pool                        => 'images',
  glance_user                        => 'images',
  libvirt_images_type                => 'rbd',
  mon_hosts                          => 'node-125',
  mon_ip_addresses                   => '192.168.0.3',
  name                               => 'Ceph',
  node_hostname                      => 'node-124',
  osd_devices                        => [],
  osd_journal_size                   => '2048',
  osd_max_backfills                  => '1',
  osd_mkfs_type                      => 'xfs',
  osd_pool_default_min_size          => '1',
  osd_pool_default_pg_num            => '256',
  osd_pool_default_pgp_num           => '256',
  osd_pool_default_size              => '2',
  osd_recovery_max_active            => '1',
  primary_mon                        => 'node-125',
  public_network                     => '192.168.0.0/24',
  rbd_cache                          => 'true',
  rbd_cache_writethrough_until_flush => 'true',
  rbd_secret_uuid                    => 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
  rgw_adm_ip                         => '192.168.0.7',
  rgw_data                           => '/var/lib/ceph/radosgw',
  rgw_dns_name                       => '*.pp',
  rgw_host                           => 'node-124',
  rgw_int_ip                         => '192.168.0.7',
  rgw_ip                             => '0.0.0.0',
  rgw_keyring_path                   => '/etc/ceph/keyring.radosgw.gateway',
  rgw_keystone_accepted_roles        => '_member_, Member, admin, swiftoperator',
  rgw_keystone_admin_token           => 'UxFQFw3m',
  rgw_keystone_revocation_interval   => '60',
  rgw_keystone_token_cache_size      => '10',
  rgw_keystone_url                   => '172.16.0.3:35357',
  rgw_log_file                       => '/var/log/ceph/radosgw.log',
  rgw_nss_db_path                    => '/etc/ceph/nss',
  rgw_port                           => '6780',
  rgw_print_continue                 => 'true',
  rgw_pub_ip                         => '172.16.0.3',
  rgw_socket_path                    => '/tmp/radosgw.sock',
  rgw_use_keystone                   => 'true',
  rgw_use_pki                        => 'false',
  show_image_direct_url              => 'True',
  swift_endpoint_port                => '8080',
  syslog_log_facility                => 'LOG_LOCAL0',
  syslog_log_level                   => 'info',
  use_rgw                            => 'true',
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

exec { 'ceph-deploy config pull':
  before    => ['Ceph_conf[global/cluster_network]', 'Ceph_conf[global/public_network]'],
  command   => 'ceph-deploy --overwrite-conf config pull node-125',
  creates   => '/etc/ceph/ceph.conf',
  cwd       => '/etc/ceph',
  path      => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  tries     => '5',
  try_sleep => '2',
}

exec { 'ceph-deploy gatherkeys remote':
  before    => 'File[/etc/ceph/ceph.client.admin.keyring]',
  command   => 'ceph-deploy gatherkeys node-125',
  creates   => ['/root/ceph.bootstrap-mds.keyring', '/root/ceph.bootstrap-osd.keyring', '/root/ceph.client.admin.keyring', '/root/ceph.mon.keyring'],
  cwd       => '/root',
  path      => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  tries     => '5',
  try_sleep => '2',
}

exec { 'ceph-deploy init config':
  command => 'ceph-deploy --overwrite-conf config push node-124',
  creates => '/etc/ceph/ceph.conf',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
}

file { '/etc/ceph/ceph.client.admin.keyring':
  ensure => 'file',
  before => 'Exec[ceph-deploy init config]',
  group  => 'root',
  mode   => '0600',
  owner  => 'root',
  path   => '/etc/ceph/ceph.client.admin.keyring',
  source => '/root/ceph.client.admin.keyring',
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
  before => 'Exec[ceph-deploy gatherkeys remote]',
  path   => '/root/ceph.conf',
  target => '/etc/ceph/ceph.conf',
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

notify { 'ceph_osd: ':
  name => 'ceph_osd: ',
}

notify { 'osd_devices:  ':
  name => 'osd_devices:  ',
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

