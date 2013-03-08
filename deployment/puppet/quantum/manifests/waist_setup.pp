class quantum::waist_setup {
  # pseudo class for divide up and down
  include 'quantum::waistline'
  
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

  Package[python-amqp] -> Class[quantum::waistline]
  Package[python-keystoneclient] -> Class[quantum::waistline]
  Nova_config<||> -> Class[quantum::waistline]

  if defined(Service[keystone]) {
    Service[keystone] -> Class[quantum::waistline]
  }
  if defined(Service[haproxy]) {
    Service[haproxy]    -> Class[quantum::waistline]
    Haproxy_service<||> -> Class[quantum::waistline]
  }
  if defined(Class[quantum]) {
    Class[quantum] -> Class[quantum::waistline]
  }
  if defined(Service[mysql-galera]) {
    Service[mysql-galera] -> Class[quantum::waistline]
  }

}