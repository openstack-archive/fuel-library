ceph::pool { 'backups':
  acl           => 'mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=backups, allow rx pool=volumes'',
  keyring_group => 'cinder',
  keyring_owner => 'cinder',
  name          => 'backups',
  pg_num        => '64',
  pgp_num       => '64',
  user          => 'backups',
}

ceph::pool { 'images':
  acl           => 'mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'',
  before        => 'Ceph::Pool[volumes]',
  keyring_group => 'glance',
  keyring_owner => 'glance',
  name          => 'images',
  pg_num        => '64',
  pgp_num       => '64',
  user          => 'images',
}

ceph::pool { 'volumes':
  acl           => 'mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images'',
  before        => 'Ceph::Pool[backups]',
  keyring_group => 'cinder',
  keyring_owner => 'cinder',
  name          => 'volumes',
  pg_num        => '64',
  pgp_num       => '64',
  user          => 'volumes',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

exec { 'Create backups Cephx user and ACL':
  before  => 'Exec[Populate backups keyring]',
  command => 'ceph auth get-or-create client.backups mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=backups, allow rx pool=volumes'',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  unless  => 'ceph auth list | grep -q '^client.backups$'',
}

exec { 'Create backups pool':
  before  => 'Exec[Create backups Cephx user and ACL]',
  command => 'ceph osd pool create backups 64 64',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  unless  => 'rados lspools | grep -q '^backups$'',
}

exec { 'Create images Cephx user and ACL':
  before  => 'Exec[Populate images keyring]',
  command => 'ceph auth get-or-create client.images mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  unless  => 'ceph auth list | grep -q '^client.images$'',
}

exec { 'Create images pool':
  before  => 'Exec[Create images Cephx user and ACL]',
  command => 'ceph osd pool create images 64 64',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  unless  => 'rados lspools | grep -q '^images$'',
}

exec { 'Create volumes Cephx user and ACL':
  before  => 'Exec[Populate volumes keyring]',
  command => 'ceph auth get-or-create client.volumes mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images'',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  unless  => 'ceph auth list | grep -q '^client.volumes$'',
}

exec { 'Create volumes pool':
  before  => 'Exec[Create volumes Cephx user and ACL]',
  command => 'ceph osd pool create volumes 64 64',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
  unless  => 'rados lspools | grep -q '^volumes$'',
}

exec { 'Populate backups keyring':
  before  => 'File[/etc/ceph/ceph.client.backups.keyring]',
  command => 'ceph auth get-or-create client.backups > /etc/ceph/ceph.client.backups.keyring',
  creates => '/etc/ceph/ceph.client.backups.keyring',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
}

exec { 'Populate images keyring':
  before  => 'File[/etc/ceph/ceph.client.images.keyring]',
  command => 'ceph auth get-or-create client.images > /etc/ceph/ceph.client.images.keyring',
  creates => '/etc/ceph/ceph.client.images.keyring',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
}

exec { 'Populate volumes keyring':
  before  => 'File[/etc/ceph/ceph.client.volumes.keyring]',
  command => 'ceph auth get-or-create client.volumes > /etc/ceph/ceph.client.volumes.keyring',
  creates => '/etc/ceph/ceph.client.volumes.keyring',
  cwd     => '/root',
  path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
}

file { '/etc/ceph/ceph.client.backups.keyring':
  ensure => 'file',
  group  => 'cinder',
  mode   => '0640',
  owner  => 'cinder',
  path   => '/etc/ceph/ceph.client.backups.keyring',
}

file { '/etc/ceph/ceph.client.images.keyring':
  ensure => 'file',
  group  => 'glance',
  mode   => '0640',
  owner  => 'glance',
  path   => '/etc/ceph/ceph.client.images.keyring',
}

file { '/etc/ceph/ceph.client.volumes.keyring':
  ensure => 'file',
  group  => 'cinder',
  mode   => '0640',
  owner  => 'cinder',
  path   => '/etc/ceph/ceph.client.volumes.keyring',
}

stage { 'main':
  name => 'main',
}

