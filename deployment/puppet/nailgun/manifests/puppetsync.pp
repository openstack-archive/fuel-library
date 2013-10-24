class nailgun::puppetsync(
  $puppet_folder = '/etc/puppet',
  $xinetd_folder = '/etc/xinet.d',
  $rsync_config  = '/etc/rsyncd.conf',
){

  file { 'rsync_conf' :
    path    => $rsync_config,
    content => template('nailgun/rsyncd.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
    
  file { 'rsync_xinetd' :
    path    => "${xinetd_folder}/rsyncd.conf",
    content => template('nailgun/rsyncd_xinetd.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  File['rsync_conf', 'rsync_xinetd'] ~> Service['xinetd']
    
}