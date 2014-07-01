class corosync::status {

  file { '/usr/local/bin/crm_ops' :
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/corosync/crm_ops.py',
  }

}
