class neutron::waist_setup {
  # pseudo class for divide up and down
  include 'neutron::waistline'

  if ! defined(Package[python-amqp]) {
    package { 'python-amqp':
      ensure => present,
    }
  }
  if ! defined(Package[python-keystoneclient]) {
    package { 'python-keystoneclient':
      ensure => present,
    }
  }

  Package['python-amqp'] -> Class['neutron::waistline']
  Package['python-keystoneclient'] -> Class['neutron::waistline']
  Nova_config<||> -> Class['neutron::waistline']

  if defined(Service['keystone']) {
    Service['keystone'] -> Class['neutron::waistline']
  }
  if defined(Class['neutron']) {
    Class['neutron'] -> Class['neutron::waistline']
  }
  #FIXME(bogdando) notify services on python-amqp/python-keystone update, if needed
}
