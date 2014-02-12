# == Class: zabbix::repo
#
# The zabbix external repository configuration.
#
class zabbix::repo {
  
  case $::operatingsystem {

    'Ubuntu': {
      case $::lsbdistcodename {
        'precise': {
          apt::ppa { 'ppa:pdffs/zabbix-stable': }
        }
        'lucid': {
          apt::source { 'zabbix':
            location   => 'http://repo.zabbix.com/zabbix/2.0/ubuntu',
            repos      => 'main',
            release    => 'lucid',
            key        => '79EA5ED4',
            key_server => 'keys.gnupg.net'
          }
        }
      }
  
    }

    'Debian': {
      apt::source { 'zabbixzone':
        location   => 'http://repo.zabbixzone.com/debian',
        repos      => 'main contrib non-free',
        release    => 'squeeze',
        key        => '25FFD7E7',
        key_server => 'keys.gnupg.net'
      }
    }

    'RedHat', 'CentOS': {
      yumrepo { 'zabbix':
        descr     => 'Zabbix Official Repository',
        baseurl   => 'http://repo.zabbix.com/zabbix/2.0/rhel/$releasever/$basearch/',
        gpgkey    => 'http://repo.zabbix.com/RPM-GPG-KEY-ZABBIX',
        gpgcheck  => 1,
        enabled   => 1,
      }
      yumrepo { 'zabbix-non-supported':
        descr     => 'Zabbix Official Repository non-supported',
        baseurl   => 'http://repo.zabbix.com/non-supported/rhel/$releasever/$basearch/',
        gpgkey    => 'http://repo.zabbix.com/RPM-GPG-KEY-ZABBIX',
        gpgcheck  => 1,
        enabled   => 1,
      }
    }
    
    'Gentoo': {
      file { '/etc/portage/package.use/10_zabbix':
        ensure    => present,
        content   => 'net-analyzer/zabbix curl'
      }
    }
    
  }
}
