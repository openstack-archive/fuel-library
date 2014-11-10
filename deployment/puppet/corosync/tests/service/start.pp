import 'service.pp'

class { 'cs_service_test' :
  service_ensure => 'running'
}