import 'resource.pp'

class { 'cs_resource_test' :
  ensure => 'present',
}
