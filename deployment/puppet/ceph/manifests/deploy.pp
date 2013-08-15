class ceph::deploy (
  $auth_supported,
  $osd_journal_size,
  $osd_mkfs_type,
) {
  include p_osd, c_osd, c_pools

  $range = join($nodes, " ")
  exec { 'ceph-deploy-s1':
    command => "ceph-deploy new ${range}",
    require => Package['ceph-deploy', 'ceph']
  }
  ceph_conf {
    'global/auth supported':          value => $auth_supported, require => Exec['ceph-deploy-s1'];
    'global/osd journal size':        value => $osd_journal_size, require => Exec['ceph-deploy-s1'];
    'global/osd mkfs type':           value => $osd_mkfs_type, require => Exec['ceph-deploy-s1'];
  }
  exec { 'ceph-deploy-s2':
    command => "ceph-deploy --overwrite-conf mon create ${range}",
    require => Ceph_conf['global/auth supported', 'global/osd journal size', 'global/osd mkfs type']
  }
  File {
    ensure => 'link',
    require => Exec['ceph-deploy-s2']
  }
  file { '/root/ceph.bootstrap-osd.keyring':
    target => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
  }
  file { '/root/ceph.bootstrap-mds.keyring':
    target => '/var/lib/ceph/bootstrap-mds/ceph.keyring',
  }
  file { '/root/ceph.client.admin.keyring':
    target => "/etc/ceph/ceph.client.admin.keyring",
  }
  class p_osd {
    define int {
      $devices = join(suffix($nodes, ":${name}"), " ")
      exec { "Cleaning drive`s on ${devices}":
        command => "ceph-deploy disk zap ${devices}",
        returns => [0,1],
        require => File['/root/ceph.bootstrap-osd.keyring','/root/ceph.bootstrap-mds.keyring','/root/ceph.client.admin.keyring']
      }
    }
    int { $osd_devices: }
  }
  class c_osd {
    define int {
      $devices = join(suffix($nodes, ":${name}"), " ")
      exec { "Creating osd`s on ${devices}":
        command => "ceph-deploy osd create ${devices}",
        returns => [0,1],
        require => Class['p_osd']
      }
    }
    int { $osd_devices: }
  }
  if $mds {
    exec { 'ceph-deploy-s4':
      command => "ceph-deploy mds create ${mds}",
      require => Class['c_osd']
    }
  }
  class c_pools {
    define int {
      exec { "Creating pool ${name}":
        command => "ceph osd pool create ${name} 128",
        require => Class['c_osd']
      }
    }
    int { $pools: }
  }
  exec { 'CLIENT AUTHENTICATION':
    command => "ceph auth get-or-create client.${pools[0]} \
    mon 'allow r' osd 'allow class-read object_prefix rbd_children, \
    allow rwx pool=${pools[0]}, allow rx pool=${pools[1]}' && \
    ceph auth get-or-create client.${pools[1]} mon 'allow r' osd \
    'allow class-read object_prefix rbd_children, allow rwx pool=${pools[1]}'",
    require => Class['c_pools']
  }
}
