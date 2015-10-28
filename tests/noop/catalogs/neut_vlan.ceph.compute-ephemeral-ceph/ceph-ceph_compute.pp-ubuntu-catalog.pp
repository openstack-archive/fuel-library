ceph::pool { 'compute':
  acl           => 'mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images, allow rwx pool=compute'',
  before        => 'Class[Ceph::Nova_compute]',
  keyring_group => 'nova',
  keyring_owner => 'nova',
  name          => 'compute',
  pg_num        => '64',
  pgp_num       => '64',
  user          => 'compute',
}

ceph_conf { 'global/cluster_network':
  before => 'File[/root/ceph.conf]',
  name   => 'global/cluster_network',
  value  => '10.122.14.0/24',
}

ceph_conf { 'global/public_network':
  before => 'File[/root/ceph.conf]',
  name   => 'global/public_network',
  value  => '10.122.12.0/24',
}

class { 'Ceph::Conf':
  before        => ['Class[Ceph::Ephemeral]', 'Ceph::Pool[compute]'],
  name          => 'Ceph::Conf',
  node_hostname => 'node-2',
}

class { 'Ceph::Ephemeral':
  libvirt_images_type => 'rbd',
  name                => 'Ceph::Ephemeral',
  notify              => 'Service[nova-compute]',
  pool                => 'compute',
  rbd_secret_uuid     => 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
}

class { 'Ceph::Nova_compute':
  compute_pool    => 'compute',
  name            => 'Ceph::Nova_compute',
  notify          => 'Service[nova-compute]',
  rbd_secret_uuid => 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
  user            => 'compute',
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
  mon_hosts                          => 'node-1',
  mon_ip_addresses                   => '10.122.12.3',
  name                               => 'Ceph',
  node_hostname                      => 'node-2',
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
  rgw_host                           => 'node-2',
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

exec { 'Create compute Cephx user and ACL':
  before  => 'Exec[Populate compute keyring]',
  command => 'ceph auth get-or-create client.compute mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images, allow rwx pool=compute'',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  unless  => 'ceph auth list | grep -q '^client.compute$'',
}

exec { 'Create compute pool':
  before  => 'Exec[Create compute Cephx user and ACL]',
  command => 'ceph osd pool create compute 64 64',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  unless  => 'rados lspools | grep -q '^compute$'',
}

exec { 'Populate compute keyring':
  before  => 'File[/etc/ceph/ceph.client.compute.keyring]',
  command => 'ceph auth get-or-create client.compute > /etc/ceph/ceph.client.compute.keyring',
  creates => '/etc/ceph/ceph.client.compute.keyring',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
}

exec { 'Set Ceph RBD secret for Nova':
  command => 'virsh secret-set-value --secret $(       virsh secret-define --file /root/secret.xml |       egrep -o '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}')       --base64 $(ceph auth get-key client.compute) &&       rm /root/secret.xml',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
}

exec { 'ceph-deploy config pull':
  before    => ['Ceph_conf[global/cluster_network]', 'Ceph_conf[global/public_network]'],
  command   => 'ceph-deploy --overwrite-conf config pull node-1',
  creates   => '/etc/ceph/ceph.conf',
  cwd       => '/etc/ceph',
  path      => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  tries     => '5',
  try_sleep => '2',
}

exec { 'ceph-deploy gatherkeys remote':
  before    => 'File[/etc/ceph/ceph.client.admin.keyring]',
  command   => 'ceph-deploy gatherkeys node-1',
  creates   => ['/root/ceph.bootstrap-mds.keyring', '/root/ceph.bootstrap-osd.keyring', '/root/ceph.client.admin.keyring', '/root/ceph.mon.keyring'],
  cwd       => '/root',
  path      => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  tries     => '5',
  try_sleep => '2',
}

exec { 'ceph-deploy init config':
  command => 'ceph-deploy --overwrite-conf config push node-2',
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

file { '/etc/ceph/ceph.client.compute.keyring':
  ensure => 'file',
  group  => 'nova',
  mode   => '0640',
  owner  => 'nova',
  path   => '/etc/ceph/ceph.client.compute.keyring',
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

file { '/root/secret.xml':
  before  => 'Service[libvirt]',
  content => '<secret ephemeral='no' private='no'>
<uuid>a5d0dd94-57c4-ae55-ffe0-7e3732a24455</uuid>
<usage type='ceph'>
<name>client.compute secret</name>
</usage>
</secret>
',
  path    => '/root/secret.xml',
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

nova_config { 'libvirt/images_rbd_pool':
  name  => 'libvirt/images_rbd_pool',
  value => 'compute',
}

nova_config { 'libvirt/images_type':
  name  => 'libvirt/images_type',
  value => 'rbd',
}

nova_config { 'libvirt/inject_key':
  name  => 'libvirt/inject_key',
  value => 'false',
}

nova_config { 'libvirt/inject_partition':
  name  => 'libvirt/inject_partition',
  value => '-2',
}

nova_config { 'libvirt/rbd_secret_uuid':
  name  => 'libvirt/rbd_secret_uuid',
  value => 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
}

nova_config { 'libvirt/rbd_user':
  name  => 'libvirt/rbd_user',
  value => 'compute',
}

package { 'ceph-deploy':
  ensure => 'installed',
  name   => 'ceph-deploy',
}

package { 'ceph':
  ensure => 'installed',
  name   => 'ceph',
}

service { 'libvirt':
  ensure => 'running',
  before => 'Exec[Set Ceph RBD secret for Nova]',
  name   => 'libvirtd',
}

service { 'nova-compute':
  name => 'nova-compute',
}

stage { 'main':
  name => 'main',
}

