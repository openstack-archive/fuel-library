class fuel::puppetsync (
  $puppet_folder    = '/etc/puppet',
  $xinetd_config    = '/etc/xinetd.d/rsync',
  $rsync_config     = '/etc/rsyncd.conf',
  $rsync_config_dir = '/etc/rsyncd.conf.d',
  $bind_address     = '0.0.0.0',
){

  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { 'rsync_conf_dir':
    path   => $rsync_config_dir,
    ensure => directory,
  }

  # template uses $bind_address and $puppet_folder
  file { 'rsync_conf' :
    path    => $rsync_config,
    content => template('fuel/rsyncd.conf.erb'),
  }

  # template uses $bind_address
  file { 'rsync_xinetd' :
    path    => $xinetd_config,
    content => template('fuel/rsyncd_xinetd.erb'),
  }

  ensure_packages(['xinetd', 'rsync'])

  if ! defined(Service['xinetd']) {
    service { 'xinetd':
      ensure  => running,
      enable  => true,
    }
  }

  Package['xinetd'] -> Service['xinetd']
  File['rsync_conf_dir'] -> Service['xinetd']
  Package['rsync'] -> File['rsync_conf']

  File['rsync_xinetd'] ~> Service['xinetd']
}
