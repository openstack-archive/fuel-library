# these parameters need to be accessed from several locations and
# should be considered to be constant
class galera::params {

  $mysql_user     = "wsrep_sst"
  $mysql_password = "password"

  case $::osfamily {
    'RedHat': {
      $pkg_provider         = 'yum'
      #$pkg_provider         = 'rpmforce'
      $libssl_package       = 'openssl098e'
      $libaio_package       = 'libaio'
      # $mysql_client_package = 'mysql'
      # $mysql_version        = '5.1/5.1.62-23.4'
      $mysql_server_package = 'MySQL-server'
      #$mysql_server_package = 'MySQL-server-5.5.28_wsrep_23.7-1.rhel5.x86_64.rpm'
      $mysql_server_name    = 'MySQL-server'
      $galera_package       = 'galera-23.2.2-1.rhel5.x86_64.rpm'
      $libgalera_prefix     = '/usr/lib64'
    }
    'Debian': {
      $pkg_provider         = 'apt'
      #$pkg_provider         = 'dpkg'
      $libssl_package       = 'libssl0.9.8'
      $libaio_package       = 'libaio1'
      # $mysql_client_package = 'mysql-client'
      # $mysql_version        = '5.5/5.5.23-23.6'
      $mysql_server_package = 'mysql-server'
      #$mysql_server_package = 'mysql-server-wsrep-5.5.28-23.7-amd64.deb'
      $mysql_server_name    = 'mysql-server-wsrep'
      $galera_package       = 'galera-23.2.2-amd64.deb'
      $libgalera_prefix     = '/usr/lib'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }

}
