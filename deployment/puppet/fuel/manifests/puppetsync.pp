class fuel::puppetsync (
  $puppet_folder = '/etc/puppet',
  $xinetd_config = '/etc/xinetd.d/rsync',
  $rsync_config  = '/etc/rsyncd.conf',
  $bind_address  = '0.0.0.0',
){

  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
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
      require => Package['xinetd'],
    }
  }

  Package['rsync'] -> File['rsync_conf', 'rsync_xinetd'] ~> Service['xinetd']
}
