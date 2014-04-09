class nailgun::puppetsync(
  $puppet_folder = '/etc/puppet',
  $xinetd_config = '/etc/xinetd.d/rsync',
  $rsync_config  = '/etc/rsyncd.conf',
){

  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { 'rsync_conf' :
    path    => $rsync_config,
    content => template('nailgun/rsyncd.conf.erb'),
  }

  file { 'rsync_xinetd' :
    path    => $xinetd_config,
    content => template('nailgun/rsyncd_xinetd.erb'),
  }

  if !defined(Package['xinetd']) {
     package { 'xinetd':
       ensure => installed,
     }
  }
  if !defined(Package['rsync']) {
     package { 'rsync':
       ensure => installed,
     }
  }
  if ! defined(Service['xinetd']) {
    service { 'xinetd':
      ensure => running,
      enable => true,
      require => Package['xinetd'],
    }
  }

  Package['rsync'] -> File['rsync_conf', 'rsync_xinetd'] ~> Service['xinetd']
}
