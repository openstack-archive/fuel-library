# these parameters need to be accessed from several locations and
# should be considered to be constant
class qpid::params {
  case $::osfamily {
    'RedHat': {
      $package_name          = 'qpid-cpp-server'
      $cluster_package_name  = 'qpid-cpp-server-cluster'
      $additional_packages   = ['qpid-cpp-server-store','qpid-cpp-server-ssl',
                                'qpid-tools']
      $service_name          = 'qpidd'
      $config_file           = '/etc/qpidd.conf'
    }
    'Debian': {
      $package_name           = 'qpidd'
      $cluster_package_name   = 'qpidd'
      $additional_packages    = 'qpidd'
      $service_name           = 'qpidd'
      $config_file            = '/etc/qpid/qpidd.conf'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }
}
