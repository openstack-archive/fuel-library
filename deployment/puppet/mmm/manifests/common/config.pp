define mmm::common::config($replication_user, $replication_password, $agent_user, 
  $agent_password, $cluster_interface, $cluster_name,
  $masters, $slaves, $readers, $writer_virtual_ip, $reader_virtual_ips) {
  
  include mmm::params
  
  case $cluster_name {
    '': {
      if !defined(File['/etc/mysql-mmm/mmm_common.conf']) {
        file { '/etc/mysql-mmm/mmm_common.conf':
          ensure  => present,
          mode    => 0600,
          owner   => 'root',
          group   => 'root',
          content => template('mmm/mmm_common.conf.erb'),
          require => Package['mysql-mmm-common'],
        }
      }
    }
    default: {
      if ($mmm::params::multi_cluster_monitor) {
        $common_dot_conf_name = "/etc/mysql-mmm/mmm_common_${cluster_name}.conf"

        # since mmm::common::config can be defined multipe times when there 
        # are multiple clusters on one monitor, we need to check here to 
        # make sure we don't double-define the normal common file to be 
        # excluded
        if defined(File['/etc/mysql-mmm/mmm_common.conf']) {
          notice('/etc/mysql-mmm/mmm_common.conf already defined, skipping in module mmm:common::config')
        } else {
          file { '/etc/mysql-mmm/mmm_common.conf':
            ensure  => absent,
          }
        }

      } else {
        $common_dot_conf_name = '/etc/mysql-mmm/mmm_common.conf'
      }
      
      file { $common_dot_conf_name:
        ensure  => present,
        mode    => 0600,
        owner   => 'root',
        group   => 'root',
        content => template('mmm/mmm_common.conf.erb'),
        require => Package['mysql-mmm-common'],
      }
    }
  }
  
}
